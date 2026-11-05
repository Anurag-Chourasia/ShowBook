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

    init(item: Book, fromBookMark: Bool = false, layout: CatalogLayout = .list, showsRatings: Bool = true) {
        self.item = item
        self.layout = layout
        self.showsRatings = showsRatings
    }

    private var imageURL: URL? {
        guard let cover = item.coverI, cover > 0 else { return nil }
        return LibraryCover.url(cover, size: .medium)
    }
    private var coverSize: CGSize { layout == .grid ? CatalogMetrics.coverGridSize : CatalogMetrics.coverListSize }

    var body: some View {
        CatalogTile(layout: layout, colors: SemanticColors(surface: ColorTheme.default.groupedSecondary)) {
            if !dynamicTypeSize.isAccessibilitySize {
                NavigationLink { BookDetailsView(book: item) } label: { cover }
                    .accessibilityLabel(String(format: String(\ShowBookStrings.detailsFor), locale: LocalizationController.shared.locale, item.title))
                    .accessibilityHint(AppRuntime.coverPreviewEnabled ? String(\ShowBookStrings.detailsPreviewHint) : String(\ShowBookStrings.detailsOpens))
                    .highPriorityGesture(LongPressGesture().onEnded { _ in if AppRuntime.coverPreviewEnabled { previewPresented = true } })
            }
        } details: {
            VStack(alignment: .leading, spacing: \.eight) {
                NavigationLink { BookDetailsView(book: item) } label: {
                    VStack(alignment: .leading, spacing: \.eight) {
                Text(item.title)
                    .font(\.headline)
                    .foregroundColor(\.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : CatalogMetrics.listTitleLines)
                Text(item.authorName?.joined(separator: ", ").nilIfEmpty ?? String(\ShowBookStrings.detailsNoAuthor))
                    .font(\.footnote)
                    .foregroundColor(\.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : CatalogMetrics.listTitleLines)
                if showsRatings && AppRuntime.ratingsEnabled, let rating = item.availableRating {
                if !dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: \.zero) {
                    ForEach(0..<CatalogMetrics.maximumRating, id: \.self) { index in
                        Image(Double(index) < rating.average.rounded(.down) ? \.starFill : \.star)
                    }
                }
                .font(\.caption)
                .foregroundColor(\.yellow)
                .accessibilityHidden(true)
                }
                Text(String(format: String(\ShowBookStrings.detailsRatings), locale: LocalizationController.shared.locale, rating.average.formatted(.number.precision(.fractionLength(0...2)).locale(LocalizationController.shared.locale)), rating.count.formatted(.number.locale(LocalizationController.shared.locale))))
                    .font(\.caption)
                    .foregroundColor(\.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                } else if showsRatings && AppRuntime.ratingsEnabled {
                    Text(String(\ShowBookStrings.notRated))
                        .font(\.caption)
                        .foregroundColor(\.secondary)
                }
                    }
                }.buttonStyle(.plain)
                .accessibilityHint(String(\ShowBookStrings.detailsOpens))
                if dynamicTypeSize.isAccessibilitySize {
                    BookmarkButton(book: item, imageUrl: imageURL)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } accessory: {
            if !dynamicTypeSize.isAccessibilitySize {
                BookmarkButton(book: item, imageUrl: imageURL)
            }
        }
        .accessibilityIdentifier(.bookTile(layout.rawValue))
        .accessibilityActions {
            if AppRuntime.coverPreviewEnabled { Button(String(\ShowBookStrings.previewCover)) { previewPresented = true } }
        }
        .sheet(isPresented: $previewPresented) {
            BookCoverPreview(coverID: item.coverI, savedImage: item.image, title: item.title)
        }
    }

    private var cover: some View {
        Group {
            if let data = item.image, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .empty: placeholder.overlay { ProgressView() }
                    default: placeholder
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

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// Search and bookmarks share the same saved preference and accessibility fallback.
struct BookLayoutPicker: View {
    var selection: Binding<CatalogLayout>? = nil
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showGridUnavailable = false

    var body: some View {
        CatalogLayoutMenu(selection: (selection?.wrappedValue ?? CatalogLayout(rawValue: storedLayout) ?? .list).resolved(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize),
                          isAccessibilitySize: dynamicTypeSize.isAccessibilitySize,
                          onSelect: { layout in
                              if let selection { selection.wrappedValue = layout }
                              else { storedLayout = layout.rawValue }
                          },
                          onGridUnavailable: { showGridUnavailable = true })
            .tint(\.primary)
            .accessibilityIdentifier(.bookLayoutMenu)
            .alert(String(\ShowBookStrings.layoutListTitle), isPresented: $showGridUnavailable) {
                Button(\.ok, role: .cancel) {}
            } message: { Text(String(\ShowBookStrings.layoutReadability)) }
    }
}

struct BookCollection: View {
    let books: [Book]
    var layoutOverride: CatalogLayout? = nil
    var showsRatings = true
    var onLastAppear: () -> Void = {}
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var layout: CatalogLayout {
        (layoutOverride ?? CatalogLayout(rawValue: storedLayout) ?? .list).resolved(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize)
    }

    var body: some View {
        Group {
            if layout == .grid {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: CatalogMetrics.bookGridMinimum), spacing: \.twelve)], spacing: \.twelve) {
                    tiles
                }
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
