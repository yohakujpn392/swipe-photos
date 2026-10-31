import Photos
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PhotoStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @State private var isTrashOpen = false

    var body: some View {
        VStack(spacing: 16) {
            if store.authorization == .denied || store.authorization == .restricted {
                noAccess
            } else if !store.isLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                header
                if store.queue.isEmpty {
                    finished
                } else {
                    SwipeDeck()
                }
            }
        }
        .padding()
        .task {
            await store.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await store.reload() }
            }
        }
        .sheet(isPresented: $isTrashOpen) {
            TrashView()
        }
        .alert("Couldn't delete photos", isPresented: errorIsShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var errorIsShown: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )
    }

    private var header: some View {
        HStack {
            Text("Left: \(store.queue.count)")
                .font(.headline)
                .monospacedDigit()
            Spacer()
            Button {
                isTrashOpen = true
            } label: {
                Label("\(store.trash.count)", systemImage: "trash")
                    .monospacedDigit()
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Trash: \(store.trash.count)")
        }
    }

    private var finished: some View {
        ContentUnavailableView {
            Label("Everything reviewed", systemImage: "checkmark.circle")
        } description: {
            Text(store.trash.isEmpty
                 ? "Kept: \(store.keptCount)"
                 : "Open the trash to delete what you marked")
        } actions: {
            if !store.trash.isEmpty {
                Button("Open Trash") { isTrashOpen = true }
                    .buttonStyle(.borderedProminent)
            }
            if !store.history.isEmpty {
                Button("Undo Last") { store.undo() }
            }
            Button("Start Over") {
                Task { await store.startOver() }
            }
        }
    }

    private var noAccess: some View {
        ContentUnavailableView {
            Label("No Photo Access", systemImage: "photo.badge.exclamationmark")
        } description: {
            Text("Allow photo library access in Settings to review your photos and videos.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
