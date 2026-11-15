import SwiftUI
import DesignTokensKit
import UIComponentsKit

struct BookCollection: View {
    let books: [Book]
    var layoutOverride: CatalogLayout? = nil
    var showsRatings = true
    var onLastAppear: () -> Void = {}
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var layout: CatalogLayout {
        let base = layoutOverride ?? CatalogLayout(rawValue: storedLayout) ?? .list
        return base.resolved(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize)
    }

    var body: some View {
        Group {
            if layout == .grid {
                let col = GridItem(.adaptive(minimum: CatalogMetrics.bookGridMinimum), spacing: \.twelve)
                LazyVGrid(columns: [col], spacing: \.twelve) { tiles }
            } else {
                LazyVStack(spacing: \.twelve) { tiles }
            }
        }
        .padding(.horizontal, \.sixteen)
    }

    private var tiles: some View {
        ForEach(books) { book in
            BookItem(item: book, layout: layout, showsRatings: showsRatings)
                .onAppear { if book.id == books.last?.id { onLastAppear() } }
        }
    }
}
