import SwiftUI
import DesignTokensKit
import UIComponentsKit

struct BookItem: View {
    let item: Book
    var layout: CatalogLayout = .list
    @State private var previewPresented = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(item: Book, fromBookMark: Bool = false, layout: CatalogLayout = .list) {
        self.item = item
        self.layout = layout
    }

    private var imageURL: URL? {
        guard let cover = item.coverI, cover > 0 else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(cover)-M.jpg")
    }
    private var coverSize: CGSize { layout == .grid ? CatalogMetrics.coverGridSize : CatalogMetrics.coverListSize }

    var body: some View {
        CatalogTile(layout: layout, colors: SemanticColors(surface: DesignColor.groupedSecondary)) {
            if !dynamicTypeSize.isAccessibilitySize {
                NavigationLink { BookDetailsView(book: item) } label: { cover }
                    .accessibilityLabel("Details for " + item.title)
                    .accessibilityHint("Tap for details. Hold to preview the cover.")
                    .highPriorityGesture(LongPressGesture().onEnded { _ in previewPresented = true })
            }
        } details: {
            VStack(alignment: .leading, spacing: Spacing.eight) {
                NavigationLink { BookDetailsView(book: item) } label: {
                    VStack(alignment: .leading, spacing: Spacing.eight) {
                Text(item.title)
                    .font(Typography.headline)
                    .foregroundStyle(DesignColor.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : CatalogMetrics.listTitleLines)
                Text(item.authorName?.joined(separator: ", ").nilIfEmpty ?? "No Author")
                    .font(Typography.footnote)
                    .foregroundStyle(DesignColor.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : CatalogMetrics.listTitleLines)
                if let rating = item.availableRating {
                if !dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: Spacing.zero) {
                    ForEach(0..<CatalogMetrics.maximumRating, id: \.self) { index in
                        Image(systemName: Double(index) < rating.average.rounded(.down) ? "star.fill" : "star")
                    }
                }
                .font(Typography.caption)
                .foregroundStyle(DesignColor.yellow)
                .accessibilityHidden(true)
                }
                Text("\(rating.average.formattedString(maxFractionDigits: 2)) average · \(rating.count) ratings")
                    .font(Typography.caption)
                    .foregroundStyle(DesignColor.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Not rated")
                        .font(Typography.caption)
                        .foregroundStyle(DesignColor.secondary)
                }
                    }
                }.buttonStyle(.plain)
                .accessibilityHint("Opens book details")
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
        .accessibilityIdentifier("book-tile-\(layout.rawValue)")
        .accessibilityAction(named: "Preview cover") { previewPresented = true }
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
        Rectangle().fill(DesignColor.grouped)
            .overlay { Image(systemName: "book.closed").foregroundStyle(DesignColor.secondary) }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// Search and bookmarks share the same saved preference and accessibility fallback.
struct BookLayoutPicker: View {
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showGridUnavailable = false

    var body: some View {
        CatalogLayoutMenu(selection: (CatalogLayout(rawValue: storedLayout) ?? .list).resolved(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize),
                          isAccessibilitySize: dynamicTypeSize.isAccessibilitySize,
                          onSelect: { storedLayout = $0.rawValue },
                          onGridUnavailable: { showGridUnavailable = true })
            .accessibilityIdentifier("book-layout-menu")
            .alert("List layout", isPresented: $showGridUnavailable) {
                Button("OK", role: .cancel) {}
            } message: { Text("List layout keeps book details readable at this text size.") }
    }
}

struct BookCollection: View {
    let books: [Book]
    var onLastAppear: () -> Void = {}
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var layout: CatalogLayout {
        (CatalogLayout(rawValue: storedLayout) ?? .list).resolved(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize)
    }

    var body: some View {
        Group {
            if layout == .grid {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: CatalogMetrics.bookGridMinimum), spacing: Spacing.twelve)], spacing: Spacing.twelve) {
                    tiles
                }
            } else {
                LazyVStack(spacing: Spacing.twelve) { tiles }
            }
        }
        .padding(.horizontal, Spacing.sixteen)
    }

    private var tiles: some View {
        ForEach(books) { book in
            BookItem(item: book, layout: layout)
                .onAppear { if book.id == books.last?.id { onLastAppear() } }
        }
    }
}
