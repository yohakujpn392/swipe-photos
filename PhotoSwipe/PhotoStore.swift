import Photos
import SwiftUI

/// Holds the review queue and the photos and videos marked for deletion.
/// Nothing leaves the library until `emptyTrash()` runs and the user confirms iOS's own dialog.
@MainActor
final class PhotoStore: ObservableObject {
    enum Decision {
        case keep
        case trash
    }

    @Published private(set) var authorization: PHAuthorizationStatus = .notDetermined
    @Published private(set) var isLoaded = false
    @Published private(set) var queue: [PHAsset] = []
    @Published private(set) var trash: [PHAsset] = []
    @Published private(set) var history: [(asset: PHAsset, decision: Decision)] = []
    @Published var errorMessage: String?
    /// Set when iOS interrupted a deletion, which Apple documents as safe to retry.
    @Published var canRetryDelete = false

    private var keptIDs: Set<String>
    private var trashIDs: [String]
    private var latestReload = 0
    private var isDeleting = false

    /// Decisions as written to disk after every swipe.
    private struct Saved: Codable {
        var kept: [String]
        var trash: [String]
    }

    private static let keptKey = "keptAssetIDs"
    private static let trashKey = "trashAssetIDs"

    private static let fileURL = URL.applicationSupportDirectory.appending(path: "decisions.json")

    init() {
        if let data = try? Data(contentsOf: Self.fileURL),
           let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            keptIDs = Set(saved.kept)
            trashIDs = saved.trash
        } else {
            // Earlier versions kept decisions in UserDefaults; carry them over once.
            let defaults = UserDefaults.standard
            keptIDs = Set(defaults.stringArray(forKey: Self.keptKey) ?? [])
            trashIDs = defaults.stringArray(forKey: Self.trashKey) ?? []
            persist()
        }
    }

    var hasAccess: Bool {
        authorization == .authorized || authorization == .limited
    }

    var keptCount: Int {
        keptIDs.count
    }

    func start() async {
        authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await reload()
    }

    /// Re-reads the library and rebuilds the queue, leaving out items already decided on.
    func reload() async {
        // Reading the library while a deletion is in progress gains nothing; it reloads once that ends.
        guard hasAccess, !isDeleting else { return }

        latestReload += 1
        let thisReload = latestReload

        let assets = await Task.detached(priority: .userInitiated) { () -> [PHAsset] in
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(
                format: "mediaType == %d OR mediaType == %d",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaType.video.rawValue
            )
            let result = PHAsset.fetchAssets(with: options)
            var assets: [PHAsset] = []
            assets.reserveCapacity(result.count)
            result.enumerateObjects { asset, _, _ in assets.append(asset) }
            return assets
        }.value

        // A newer reload has started, and this result may still list items deleted since.
        guard thisReload == latestReload else { return }

        // Filtered here, not in the detached task, so swipes made during the fetch are respected.
        let pending = Set(trashIDs)
        queue = assets.filter { !keptIDs.contains($0.localIdentifier) && !pending.contains($0.localIdentifier) }
        trash = assets.filter { pending.contains($0.localIdentifier) }
        isLoaded = true
    }

    func decide(_ decision: Decision, on asset: PHAsset) {
        // Matched by identifier, since a reload may have replaced the queue's asset objects mid-swipe.
        guard let index = queue.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) else { return }
        queue.remove(at: index)
        history.append((asset, decision))

        switch decision {
        case .keep:
            keptIDs.insert(asset.localIdentifier)
        case .trash:
            trash.insert(asset, at: 0)
            trashIDs.append(asset.localIdentifier)
        }
        persist()
    }

    func undo() {
        guard let last = history.popLast() else { return }

        switch last.decision {
        case .keep:
            keptIDs.remove(last.asset.localIdentifier)
        case .trash:
            trash.removeAll { $0 == last.asset }
            trashIDs.removeAll { $0 == last.asset.localIdentifier }
        }
        queue.insert(last.asset, at: 0)
        persist()
    }

    /// Takes an item back out of the trash and returns it to the front of the queue.
    func restore(_ asset: PHAsset) {
        trash.removeAll { $0 == asset }
        trashIDs.removeAll { $0 == asset.localIdentifier }
        history.removeAll { $0.asset == asset }
        queue.insert(asset, at: 0)
        persist()
    }

    /// Moves the marked items to "Recently Deleted". iOS shows its own confirmation first.
    /// The change is all or nothing, so after any failure every marked item is still in the library.
    func emptyTrash() async {
        guard !trash.isEmpty, !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        canRetryDelete = false

        // Fresh objects, so items deleted elsewhere in the meantime (another device, the Photos app) drop out.
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: trashIDs, options: nil)
        var assets: [PHAsset] = []
        fetched.enumerateObjects { asset, _, _ in assets.append(asset) }
        let present = Set(assets.map(\.localIdentifier))
        if present.count < trashIDs.count {
            trashIDs.removeAll { !present.contains($0) }
            trash.removeAll { !present.contains($0.localIdentifier) }
            persist()
        }
        guard !assets.isEmpty else { return }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }
        } catch {
            let nsError = error as NSError
            guard nsError.domain == PHPhotosErrorDomain else {
                errorMessage = error.localizedDescription
                return
            }
            switch nsError.code {
            case PHPhotosError.userCancelled.rawValue:
                // Declining the system dialog lands here, and that isn't a failure worth reporting.
                break
            case PHPhotosError.operationInterrupted.rawValue:
                errorMessage = "iOS interrupted the deletion, so nothing was deleted. Your marked items are still in the trash."
                canRetryDelete = true
            default:
                errorMessage = "Nothing was deleted, and your marked items are still in the trash. \(error.localizedDescription)"
            }
            return
        }

        trash.removeAll { present.contains($0.localIdentifier) }
        trashIDs.removeAll { present.contains($0) }
        history.removeAll { present.contains($0.asset.localIdentifier) }
        persist()
        isDeleting = false
        await reload()
    }

    /// Forgets which items were kept, so the whole library comes up for review again.
    func startOver() async {
        keptIDs.removeAll()
        history.removeAll()
        persist()
        await reload()
    }

    /// Written straight to a file after every decision, so closing or killing the app loses nothing.
    private func persist() {
        let saved = Saved(kept: Array(keptIDs), trash: trashIDs)
        do {
            try FileManager.default.createDirectory(at: Self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(saved).write(to: Self.fileURL, options: .atomic)
        } catch {
            errorMessage = "Couldn't save your progress. \(error.localizedDescription)"
        }
    }
}
