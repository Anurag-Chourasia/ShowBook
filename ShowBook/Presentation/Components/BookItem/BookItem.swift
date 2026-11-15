import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

struct BookItem: View {
    let item: Book
    var layout: CatalogLayout = .list
    var showsRatings = true
    @State private var previewPresented = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.persistenceController) private var persistenceController

    init(item: Book, fromBookMark: Bool = false, layout: CatalogLayout = .list, showsRatings: Bool = true) {
        self.item = item
        self.layout = layout
        self.showsRatings = showsRatings
    }

    var body: some View {
        CatalogTile(layout: layout, colors: SemanticColors(surface: \.groupedSecondary)) {
            if !dynamicTypeSize.isAccessibilitySize {
                NavigationLink { BookDetailsView(book: item) } label: { BookItemCover(item: item, layout: layout) }
                    .accessibilityLabel(Text(\.detailsFor, arguments: [item.title]))
                    .accessibilityHint(AppRuntime.coverPreviewEnabled ? Text(\.detailsPreviewHint) : Text(\.detailsOpens))
                    .highPriorityGesture(LongPressGesture().onEnded { _ in
                        if AppRuntime.coverPreviewEnabled { previewPresented = true }
                    })
            }
        } details: {
            VStack(alignment: .leading, spacing: \.eight) {
                NavigationLink { BookDetailsView(book: item) } label: {
                    BookItemDetailsView(item: item, showsRatings: showsRatings)
                }
                .buttonStyle(.plain)
                .accessibilityHint(\.detailsOpens)
                if dynamicTypeSize.isAccessibilitySize { bookmarkButton }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } accessory: {
            if !dynamicTypeSize.isAccessibilitySize { bookmarkButton }
        }
        .accessibilityIdentifier(.bookTile(layout.rawValue))
        .accessibilityActions {
            if AppRuntime.coverPreviewEnabled { Button(\.previewCover) { previewPresented = true } }
        }
        .sheet(isPresented: $previewPresented) {
            BookCoverPreview(coverID: item.coverI, savedImage: item.image, title: item.title)
        }
    }

    private var bookmarkButton: some View {
        BookmarkButton(
            book: item,
            imageUrl: item.coverI.flatMap { LibraryCover.url($0, size: .medium) },
            persistenceController: persistenceController
        )
    }
}
