import SwiftUI

/// The photos marked for deletion: tap one to take it back, or delete them all at once.
struct TrashView: View {
    @EnvironmentObject private var store: PhotoStore
    @Environment(\.dismiss) private var dismiss

    @State private var isDeleting = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    var body: some View {
        NavigationStack {
            Group {
                if store.trash.isEmpty {
                    ContentUnavailableView("Trash Is Empty", systemImage: "trash")
                } else {
                    ScrollView {
                        Text("Tap a photo to put it back")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)

                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(store.trash, id: \.localIdentifier) { asset in
                                Button {
                                    store.restore(asset)
                                } label: {
                                    Color(white: 0.1)
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay {
                                            AssetImage(asset: asset, pixelSize: 300, contentMode: .fill)
                                        }
                                        .clipped()
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Put photo back")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trash")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !store.trash.isEmpty {
                    deleteButton
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            guard !isDeleting else { return }
            isDeleting = true
            Task {
                await store.emptyTrash()
                isDeleting = false
                if store.trash.isEmpty {
                    dismiss()
                }
            }
        } label: {
            Text(store.trash.count == 1 ? "Delete 1 Photo" : "Delete \(store.trash.count) Photos")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .opacity(isDeleting ? 0.6 : 1)
        .padding()
        .background(.bar)
    }
}
