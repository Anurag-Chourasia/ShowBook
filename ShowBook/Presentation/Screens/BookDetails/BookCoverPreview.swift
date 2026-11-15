import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

/// Uses the large cover when available and retains saved artwork for offline viewing.
struct BookCoverPreview: View {
    let coverID: Int?
    let savedImage: Data?
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var loading = true
    @State private var sharing = false
    @State private var shareError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFit().accessibilityLabel(title)
                } else if loading { ProgressView { Text(\.loadingCover) } } else { unavailable }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(\.sixteen)
            .background(\.grouped)
            .accessibilityIdentifier(.bookCoverPreview)
            .navigationTitle(\.detailsCoverPreview)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(\.close) }
                        .accessibilityLabel(\.closeCoverPreview)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sharing = true } label: {
                        Label(Text(\.shareCover), \.squareAndArrowUp)
                    }
                    .disabled(image == nil)
                    .accessibilityIdentifier(.shareCover)
                }
            }
            .tint(\.primary)
            .sheet(isPresented: $sharing) {
                if let image {
                    CoverShareSheet(image: image) { error in
                        shareError = error.localizedDescription
                    }
                }
            }
            .alert(Text(\.detailsShareFailed), isPresented: Binding(
                get: { shareError != nil }, set: { if !$0 { shareError = nil } }
            )) { Button(\.ok, role: .cancel) {} } message: { Text(shareError ?? "") }
            .task {
                image = savedImage.flatMap(UIImage.init(data:))
                defer { loading = false }
                guard let url = LibraryCover.url(coverID) else { return }
                do {
                    let data = try await AppDI.shared.imageDataLoader.loadImageData(from: url)
                    try Task.checkCancellation()
                    if let loaded = UIImage(data: data) {
                        image = loaded
                    }
                } catch { /* Retain saved artwork when offline. */ }
            }
        }
    }

    private var unavailable: some View {
        VStack(spacing: \.twelve) {
            Image(\.bookClosed).font(\.largeTitle)
            Text(\.coverUnavailable).font(\.headline)
        }.foregroundColor(\.secondary)
    }
}

/// Pass the image itself so iOS offers image-compatible destinations and
/// system actions, including Save Image and Save to Files.
private struct CoverShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let onError: (Error) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, error in
            if let error { onError(error) }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
