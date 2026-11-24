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
                LibraryCover(
                    coverID: model.work?.covers?.first(where: { $0 > 0 }) ?? book.coverI,
                    savedImage: book.image ?? persistenceController.bookExists(book)?.image
                )
                    .frame(maxWidth: .infinity)
                Text(model.work?.title ?? book.title).font(\.title).accessibilityAddTraits(.isHeader)
                if let authors = book.authorName, !authors.isEmpty {
                    Text(authors.joined(separator: ", ")).font(\.body).foregroundColor(\.secondary)
                }
                BookmarkButton(book: book, imageUrl: LibraryCover.url(book.coverI), persistenceController: persistenceController)
                if model.loading && model.work == nil { ProgressView { Text(\.loadingBookDetails) } }
                if let error = model.error {
                    Text(error).foregroundColor(\.secondary)
                    if book.key != nil { Button(\.retry) { reload += 1 } }
                }
                if let work = model.work {
                    detailSection(\.description, text: work.description?.value ?? String(\.noDescription))
                    if let date = work.first_publish_date { detailSection(\.firstPublished, text: date) }
                    if let subjects = work.subjects, !subjects.isEmpty {
                        detailSection(\.subjects, text: subjects.joined(separator: " · "))
                    }
                    Text(\.editions).font(\.title2).accessibilityAddTraits(.isHeader)
                    ForEach(model.editions) { edition in
                        NavigationLink {
                            EditionDetailsView(
                                key: edition.key,
                                title: edition.title,
                                service: appDI.bookDetailsService
                            )
                        } label: {
                            SurfaceCard {
                                VStack(alignment: .leading, spacing: \.eight) {
                                    Text(edition.title).font(\.headline)
                                    if let date = edition.publish_date { Text(date).font(\.subheadline) }
                                    if let publishers = edition.publishers { Text(publishers.joined(separator: ", ")).font(\.footnote) }
                                    Label(Text(\.editionDetails), \.chevronRight).font(\.caption)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }.buttonStyle(.plain)
                    }
                    if let error = model.editionsError { Text(error).foregroundColor(\.secondary) }
                    if model.loadingEditions { ProgressView { Text(\.loadingEditions) } } else if model.hasMoreEditions {
                        Button(model.editionsError == nil ? \.loadMoreEditions : \.retryEditions) { more += 1 }
                    } else if model.editions.isEmpty { Text(\.noEditions) }
                }
            }.padding(\.twenty)
        }
        .navigationTitle(\.bookDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .showBookTools()
        .task(id: reload) { await model.load() }
        .task(id: more) { if more > 0 { await model.loadMoreEditions() } }
    }
    private func detailSection(_ titleKeyPath: KeyPath<ShowBookStrings, String>, text: String) -> some View {
        VStack(alignment: .leading, spacing: \.eight) {
            Text(titleKeyPath).font(\.title2).accessibilityAddTraits(.isHeader)
            Text(text).font(\.body).textSelection(.enabled)
        }
    }
}
