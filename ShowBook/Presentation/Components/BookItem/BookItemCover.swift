import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

struct BookItemCover: View {
    let item: Book
    let layout: CatalogLayout

    private var imageURL: URL? {
        guard let cover = item.coverI, cover > 0 else { return nil }
        return LibraryCover.url(cover, size: .medium)
    }

    private var coverSize: CGSize {
        layout == .grid ? CatalogMetrics.coverGridSize : CatalogMetrics.coverListSize
    }

    var body: some View {
        Group {
            if let data = item.image, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let imageURL {
                RemoteImagePhaseView(url: imageURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .empty, .loading: placeholder.overlay { ProgressView() }
                    case .failure: placeholder
                    }
                }
            } else { placeholder }
        }
        .frame(width: coverSize.width, height: coverSize.height)
        .clipShape(RoundedRectangle(cornerRadius: CatalogMetrics.coverRadius))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Rectangle().fill(\.grouped)
            .overlay { Image(\.bookClosed).foregroundColor(\.secondary) }
    }
}
