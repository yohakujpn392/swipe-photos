import Photos
import SwiftUI

/// The stack of photo cards: drag right to keep, drag left to mark for deletion.
struct SwipeDeck: View {
    @EnvironmentObject private var store: PhotoStore

    @State private var offset: CGSize = .zero
    @State private var flight: Flight?

    /// A card on its way off screen, whose decision hasn't been recorded yet.
    private struct Flight {
        let id = UUID()
        let asset: PHAsset
        let decision: PhotoStore.Decision
    }

    private let threshold: CGFloat = 110

    private var isPastThreshold: Bool {
        abs(offset.width) > threshold
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(Array(store.queue.prefix(2).enumerated().reversed()), id: \.element.localIdentifier) { index, asset in
                    card(for: asset, isTop: index == 0)
                }
            }
            .contentShape(Rectangle())
            .gesture(drag)
            .sensoryFeedback(.impact(weight: .light), trigger: isPastThreshold) { _, isPast in isPast }

            buttons
        }
    }

    private func card(for asset: PHAsset, isTop: Bool) -> some View {
        AssetImage(asset: asset, pixelSize: 1600, contentMode: .fit)
            .background(Color(white: 0.1))
            .overlay(alignment: .bottomLeading) {
                if let date = asset.creationDate {
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(12)
                }
            }
            .overlay {
                if isTop {
                    verdictOverlay
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .scaleEffect(isTop ? 1 : 0.95)
            .offset(isTop ? offset : .zero)
            .rotationEffect(.degrees(isTop ? Double(offset.width / 22) : 0))
    }

    private var verdictOverlay: some View {
        let progress = min(abs(offset.width) / threshold, 1)
        let isKeep = offset.width > 0

        return ZStack {
            (isKeep ? Color.green : Color.red).opacity(progress * 0.25)
            Label(isKeep ? "Keep" : "Trash", systemImage: isKeep ? "checkmark" : "trash")
                .font(.title2.bold())
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isKeep ? Color.green : Color.red, in: Capsule())
                .foregroundStyle(.white)
                .opacity(progress)
        }
        .allowsHitTesting(false)
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                finishFlight()
                offset = value.translation
            }
            .onEnded { value in
                if value.predictedEndTranslation.width > threshold, value.translation.width > 0 {
                    fly(.keep)
                } else if value.predictedEndTranslation.width < -threshold, value.translation.width < 0 {
                    fly(.trash)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        offset = .zero
                    }
                }
            }
    }

    /// Animates the top card off screen, then records the decision.
    private func fly(_ decision: PhotoStore.Decision) {
        finishFlight()
        guard let asset = store.queue.first else { return }

        let newFlight = Flight(asset: asset, decision: decision)
        flight = newFlight
        withAnimation(.easeOut(duration: 0.22)) {
            offset = CGSize(width: decision == .keep ? 800 : -800, height: offset.height)
        } completion: {
            if flight?.id == newFlight.id {
                finishFlight()
            }
        }
    }

    /// Records the decision for a card still in the air, so the next swipe is never lost.
    private func finishFlight() {
        guard let finished = flight else { return }
        flight = nil
        store.decide(finished.decision, on: finished.asset)

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            offset = .zero
        }
    }

    private var buttons: some View {
        HStack(spacing: 28) {
            roundButton("trash", color: .red, label: "Move to Trash") {
                fly(.trash)
            }
            roundButton("arrow.uturn.backward", color: .gray, label: "Undo") {
                finishFlight()
                store.undo()
            }
            .disabled(store.history.isEmpty && flight == nil)
            .opacity(store.history.isEmpty && flight == nil ? 0.4 : 1)
            roundButton("checkmark", color: .green, label: "Keep") {
                fly(.keep)
            }
        }
    }

    private func roundButton(_ symbol: String, color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 64, height: 64)
                .background(color.opacity(0.2), in: Circle())
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
