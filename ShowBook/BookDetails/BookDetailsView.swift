import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

struct BookDetailsView: View {
    let book: Book
    @StateObject private var model: BookDetailsViewModel
    @State private var reload = 0
    @State private var more = 0

    init(book: Book, model: BookDetailsViewModel? = nil) {
        self.book = book
        _model = StateObject(wrappedValue: model ?? BookDetailsViewModel(key: book.key))
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
                BookmarkButton(book: book, imageUrl: LibraryCover.url(book.coverI))
                if model.loading && model.work == nil { ProgressView("Loading book details…") }
                if let error = model.error {
                    Text(error).foregroundColor(\.secondary)
                    if book.key != nil { Button("Retry") { reload += 1 } }
                }
                if let work = model.work {
                    detailSection("Description", text: work.description?.value ?? "No description available.")
                    if let date = work.first_publish_date { detailSection("First published", text: date) }
                    if let subjects = work.subjects, !subjects.isEmpty {
                        detailSection("Subjects", text: subjects.joined(separator: " · "))
                    }
                    Text("Editions").font(\.title2).accessibilityAddTraits(.isHeader)
                    ForEach(model.editions) { edition in
                        NavigationLink { EditionDetailsView(key: edition.key, title: edition.title) } label: {
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
                    if model.loadingEditions { ProgressView("Loading editions…") }
                    else if model.hasMoreEditions {
                        Button(model.editionsError == nil ? "Load more editions" : "Retry editions") { more += 1 }
                    } else if model.editions.isEmpty { Text("No editions available.") }
                }
            }.padding(\.twenty)
        }
        .navigationTitle("Book details")
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
    @State private var edition: LibraryEdition?
    @State private var error: String?
    @State private var loading = true
    @State private var reload = 0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: \.sixteen) {
                Text(edition?.title ?? title).font(\.title).accessibilityAddTraits(.isHeader)
                if loading { ProgressView("Loading edition…") }
                if let error { Text(error); Button("Retry") { reload += 1 } }
                if let edition {
                    LibraryCover(coverID: edition.covers?.first(where: { $0 > 0 }), savedImage: nil)
                    field("Published", edition.publish_date)
                    field("Publisher", edition.publishers?.joined(separator: ", "))
                    field("Format", edition.physical_format)
                    field("Pages", edition.number_of_pages.map(String.init))
                    field("ISBN-13", edition.isbn_13?.joined(separator: ", "))
                    field("ISBN-10", edition.isbn_10?.joined(separator: ", "))
                    field("Languages", edition.languages?.map { reference in
                        let code = reference.key.components(separatedBy: "/").last ?? ""
                        return Locale.current.localizedString(forLanguageCode: code) ?? code
                    }.joined(separator: ", "))
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(\.twenty)
        }
        .navigationTitle("Edition details").navigationBarTitleDisplayMode(.inline)
        .showBookTools()
        .task(id: reload) {
            loading = true; error = nil
            defer { loading = false }
            do {
                let result = try await BookDetailsService.shared.edition(key: key)
                try Task.checkCancellation()
                edition = result
            } catch is CancellationError { }
            catch { if !Task.isCancelled { self.error = BookDetailsViewModel.message(error) } }
        }
    }
    private func field(_ title: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: \.four) {
            Text(title).font(\.headline)
            Text(value?.isEmpty == false ? value! : "Not available").font(\.body).textSelection(.enabled)
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
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFit() }
                    else if phase.error != nil { placeholder }
                    else { ProgressView() }
                }
            } else { placeholder }
        }
        .frame(width: CatalogMetrics.coverGridSize.width, height: CatalogMetrics.coverGridSize.height)
        .contentShape(Rectangle())
        .onLongPressGesture { if AppRuntime.coverPreviewEnabled { previewPresented = true } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Book cover")
        .accessibilityActions {
            if AppRuntime.coverPreviewEnabled { Button("Preview cover") { previewPresented = true } }
        }
        .sheet(isPresented: $previewPresented) {
            BookCoverPreview(coverID: coverID, savedImage: savedImage, title: "Book cover")
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
                } else if loading { ProgressView("Loading cover…") }
                else { unavailable }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(\.sixteen)
            .background(\.grouped)
            .accessibilityIdentifier(.bookCoverPreview)
            .navigationTitle("Cover preview")
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
            .alert("Couldn’t share cover", isPresented: Binding(
                get: { shareError != nil }, set: { if !$0 { shareError = nil } }
            )) { Button(\.ok, role: .cancel) {} } message: { Text(shareError ?? "") }
            .task {
                image = savedImage.flatMap(UIImage.init(data:))
                defer { loading = false }
                guard let url = LibraryCover.url(coverID) else { return }
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    try Task.checkCancellation()
                    if let response = response as? HTTPURLResponse,
                       (200..<300).contains(response.statusCode), let loaded = UIImage(data: data) {
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
