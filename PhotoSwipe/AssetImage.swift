import Photos
import SwiftUI

/// Shows a library photo or a video's thumbnail: a blurry preview first, then the full version (downloaded from iCloud if needed).
struct AssetImage: View {
    let asset: PHAsset
    let pixelSize: CGFloat
    let contentMode: ContentMode

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if didFail {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Failed to load")
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: asset.localIdentifier) {
            for await next in Self.images(for: asset, pixelSize: pixelSize) {
                image = next
            }
            didFail = image == nil && !Task.isCancelled
        }
    }

    private static func images(for asset: PHAsset, pixelSize: CGFloat) -> AsyncStream<UIImage> {
        AsyncStream { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            let manager = PHImageManager.default()
            let request = manager.requestImage(
                for: asset,
                targetSize: CGSize(width: pixelSize, height: pixelSize),
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let image {
                    continuation.yield(image)
                }
                let isPreview = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                if !isPreview {
                    continuation.finish()
                }
            }
            continuation.onTermination = { _ in
                manager.cancelImageRequest(request)
            }
        }
    }
}
