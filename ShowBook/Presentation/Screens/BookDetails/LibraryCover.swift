import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

struct LibraryCover: View {
    let coverID: Int?
    let savedImage: Data?
    @State private var previewPresented = false
    enum CoverSize: String { case medium = "M", large = "L" }

    static func url(_ id: Int?, size: CoverSize = .large) -> URL? {
        guard AppRuntime.stubScenario == nil, let id, id > 0 else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(id)-\(size.rawValue).jpg?default=false")
    }

    var body: some View {
        Group {
            if let savedImage, let image = UIImage(data: savedImage) {
                Image(uiImage: image).resizable().scaledToFit()
            } else if let url = Self.url(coverID) {
                RemoteImagePhaseView(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else if phase.error != nil {
                        placeholder
                    } else {
                        ProgressView()
                    }
                }
            } else { placeholder }
        }
        .frame(width: CatalogMetrics.coverGridSize.width, height: CatalogMetrics.coverGridSize.height)
        .contentShape(Rectangle())
        .onLongPressGesture { if AppRuntime.coverPreviewEnabled { previewPresented = true } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(\.detailsBookCover)
        .accessibilityActions {
            if AppRuntime.coverPreviewEnabled { Button(\.previewCover) { previewPresented = true } }
        }
        .sheet(isPresented: $previewPresented) {
            BookCoverPreview(coverID: coverID, savedImage: savedImage, title: String(\.detailsBookCover))
        }
    }

    private var placeholder: some View {
        Image(\.bookClosed).font(\.largeTitle).foregroundColor(\.secondary)
    }
}
