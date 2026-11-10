import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

struct BookDetailsView: View {
    let book: Book
    @StateObject private var model: BookDetailsViewModel
    @State private var reload = 0
    @State private var more = 0
    @Environment(\.persistenceController) private var persistenceController
    @Environment(\.appDI) private var appDI

    init(book: Book, model: BookDetailsViewModel? = nil) {
        self.book = book
        _model = StateObject(wrappedValue: model ?? AppDI.shared.makeBookDetailsViewModel(key: book.key))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: \.twenty) {
                LibraryCover(coverID: model.work?.covers?.first(where: { $0 > 0 }) ?? book.coverI, savedImage: book.image)
                    .frame(maxWidth: .infinity)
                Text(model.work?.title ?? book.title).font(\.title).accessibilityAddTraits(.isHeader)
                if let authors = book.authorName, !authors.isEmpty {
                    Text(authors.joined(separator: ", ")).font(\.body).foregroundColor(\.secondary)
                }
                BookmarkButton(book: book, imageUrl: LibraryCover.url(book.coverI), persistenceController: persistenceController)
                if model.loading && model.work == nil { ProgressView(String(\ShowBookStrings.loadingBookDetails)) }
                if let error = model.error {
                    Text(error).foregroundColor(\.secondary)
                    if book.key != nil { Button(String(\CommonStrings.retry)) { reload += 1 } }
                }
                if let work = model.work {
                    detailSection(String(\ShowBookStrings.description), text: work.description?.value ?? String(\ShowBookStrings.noDescription))
                    if let date = work.first_publish_date { detailSection(String(\ShowBookStrings.firstPublished), text: date) }
                    if let subjects = work.subjects, !subjects.isEmpty {
                        detailSection(String(\ShowBookStrings.subjects), text: subjects.joined(separator: " · "))
                    }
                    Text(String(\ShowBookStrings.editions)).font(\.title2).accessibilityAddTraits(.isHeader)
                    ForEach(model.editions) { edition in
                        NavigationLink { EditionDetailsView(key: edition.key, title: edition.title, service: appDI.bookDetailsService) } label: {
                            SurfaceCard {
                                VStack(alignment: .leading, spacing: \.eight) {
                                    Text(edition.title).font(\.headline)
                                    if let date = edition.publish_date { Text(date).font(\.subheadline) }
                                    if let publishers = edition.publishers { Text(publishers.joined(separator: ", ")).font(\.footnote) }
                                    Label(Text(\.editionDetails), \.chevronRight).font(\.caption)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }.buttonStyle(.plain)
                    }
                    if let error = model.editionsError { Text(error).foregroundColor(\.secondary) }
                    if model.loadingEditions { ProgressView(String(\ShowBookStrings.loadingEditions)) } else if model.hasMoreEditions {
                        Button(model.editionsError == nil ? String(\ShowBookStrings.loadMoreEditions) : String(\ShowBookStrings.retryEditions)) { more += 1 }
                    } else if model.editions.isEmpty { Text(String(\ShowBookStrings.noEditions)) }
                }
            }.padding(\.twenty)
        }
        .navigationTitle(String(\ShowBookStrings.bookDetailsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .showBookTools()
        .task(id: reload) { await model.load() }
        .task(id: more) { if more > 0 { await model.loadMoreEditions() } }
    }
    private func detailSection(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: \.eight) {
            Text(title).font(\.title2).accessibilityAddTraits(.isHeader)
            Text(text).font(\.body).textSelection(.enabled)
        }
    }
}

struct EditionDetailsView: View {
    let key: String
    let title: String
    var service: any BookDetailsServing
    @State private var edition: LibraryEdition?
    @State private var error: String?
    @State private var loading = true
    @State private var reload = 0

    init(key: String, title: String, service: (any BookDetailsServing)? = nil) {
        self.key = key
        self.title = title
        self.service = service ?? AppDI.shared.bookDetailsService
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: \.sixteen) {
                Text(edition?.title ?? title).font(\.title).accessibilityAddTraits(.isHeader)
                if loading { ProgressView(String(\ShowBookStrings.loadingEdition)) }
                if let error { Text(error); Button(String(\CommonStrings.retry)) { reload += 1 } }
                if let edition {
                    LibraryCover(coverID: edition.covers?.first(where: { $0 > 0 }), savedImage: nil)
                    field(String(\ShowBookStrings.published), edition.publish_date)
                    field(String(\ShowBookStrings.publisher), edition.publishers?.joined(separator: ", "))
                    field(String(\ShowBookStrings.format), edition.physical_format)
                    field(String(\ShowBookStrings.pages), edition.number_of_pages.map(String.init))
                    field(String(\ShowBookStrings.isbn13), edition.isbn_13?.joined(separator: ", "))
                    field(String(\ShowBookStrings.isbn10), edition.isbn_10?.joined(separator: ", "))
                    field(String(\ShowBookStrings.languages), edition.languages?.map { reference in
                        let code = reference.key.components(separatedBy: "/").last ?? ""
                        return Locale.current.localizedString(forLanguageCode: code) ?? code
                    }.joined(separator: ", "))
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(\.twenty)
        }
        .navigationTitle(String(\ShowBookStrings.editionDetailsTitle)).navigationBarTitleDisplayMode(.inline)
        .showBookTools()
        .task(id: reload) {
            loading = true; error = nil
            defer { loading = false }
            do {
                let result = try await service.edition(key: key)
                try Task.checkCancellation()
                edition = result
            } catch is CancellationError { }
            catch { if !Task.isCancelled { self.error = BookDetailsViewModel.message(error) } }
        }
    }
    private func field(_ title: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: \.four) {
            Text(title).font(\.headline)
            Text(value.flatMap { $0.isEmpty ? nil : $0 } ?? String(\ShowBookStrings.detailsNotAvailable)).font(\.body).textSelection(.enabled)
        }
    }
}

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
        .accessibilityLabel(String(\ShowBookStrings.detailsBookCover))
        .accessibilityActions {
            if AppRuntime.coverPreviewEnabled { Button(String(\ShowBookStrings.previewCover)) { previewPresented = true } }
        }
        .sheet(isPresented: $previewPresented) {
            BookCoverPreview(coverID: coverID, savedImage: savedImage, title: String(\ShowBookStrings.detailsBookCover))
        }
    }
    private var placeholder: some View { Image(\.bookClosed).font(\.largeTitle).foregroundColor(\.secondary) }
}

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
                } else if loading { ProgressView(String(\ShowBookStrings.loadingCover)) } else { unavailable }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(\.sixteen)
            .background(\.grouped)
            .accessibilityIdentifier(.bookCoverPreview)
            .navigationTitle(String(\ShowBookStrings.detailsCoverPreview))
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
            .alert(String(\ShowBookStrings.detailsShareFailed), isPresented: Binding(
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
