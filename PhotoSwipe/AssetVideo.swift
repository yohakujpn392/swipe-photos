import AVFoundation
import Photos
import SwiftUI

/// Plays a library video on a loop, on top of its thumbnail (downloaded from iCloud if needed).
struct AssetVideo: View {
    let asset: PHAsset
    let isMuted: Bool

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        PlayerLayerView(player: player)
            .allowsHitTesting(false)
            .task(id: asset.localIdentifier) {
                guard let item = await Self.playerItem(for: asset), !Task.isCancelled else { return }
                let newPlayer = AVQueuePlayer()
                looper = AVPlayerLooper(player: newPlayer, templateItem: item)
                newPlayer.isMuted = isMuted
                newPlayer.play()
                player = newPlayer
            }
            .onChange(of: isMuted) { _, muted in
                player?.isMuted = muted
            }
            .onDisappear {
                player?.pause()
            }
    }

    private static func playerItem(for asset: PHAsset) async -> AVPlayerItem? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .automatic
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }
}

/// `VideoPlayer` brings its own controls and swallows drags, so the card uses a bare player layer.
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer?

    final class LayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    func makeUIView(context: Context) -> LayerView {
        let view = LayerView()
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ view: LayerView, context: Context) {
        view.playerLayer.player = player
    }
}

extension PHAsset {
    var isVideo: Bool {
        mediaType == .video
    }

    var durationText: String {
        Duration.seconds(duration).formatted(.time(pattern: .minuteSecond))
    }
}
