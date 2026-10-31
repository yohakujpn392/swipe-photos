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

    private var keptIDs: Set<String>
    private var trashIDs: [String]
    private var latestReload = 0

    private static let keptKey = "keptAssetIDs"
    private static let trashKey = "trashAssetIDs"

    init() {
        let defaults = UserDefaults.standard
        keptIDs = Set(defaults.stringArray(forKey: Self.keptKey) ?? [])
        trashIDs = defaults.stringArray(forKey: Self.trashKey) ?? []
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
        guard hasAccess else { return }

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
        guard let index = queue.firstIndex(of: asset) else { return }
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
    func emptyTrash() async {
        let assets = trash
        guard !assets.isEmpty else { return }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }
        } catch {
            // Declining the system dialog also lands here, and that isn't a failure worth reporting.
            let nsError = error as NSError
            let declined = nsError.domain == PHPhotosErrorDomain
                && nsError.code == PHPhotosError.userCancelled.rawValue
            if !declined {
                errorMessage = error.localizedDescription
            }
            return
        }

        let deleted = Set(assets.map(\.localIdentifier))
        trash.removeAll { deleted.contains($0.localIdentifier) }
        trashIDs.removeAll { deleted.contains($0) }
        history.removeAll { deleted.contains($0.asset.localIdentifier) }
        persist()
        await reload()
    }

    /// Forgets which items were kept, so the whole library comes up for review again.
    func startOver() async {
        keptIDs.removeAll()
        history.removeAll()
        persist()
        await reload()
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(Array(keptIDs), forKey: Self.keptKey)
        defaults.set(trashIDs, forKey: Self.trashKey)
    }
}
