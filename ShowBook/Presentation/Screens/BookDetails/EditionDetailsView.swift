import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

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
                if loading { ProgressView { Text(\.loadingEdition) } }
                if let error { Text(error); Button(\.retry) { reload += 1 } }
                if let edition {
                    LibraryCover(coverID: edition.covers?.first(where: { $0 > 0 }), savedImage: nil)
                    field(\.published, edition.publish_date)
                    field(\.publisher, edition.publishers?.joined(separator: ", "))
                    field(\.format, edition.physical_format)
                    field(\.pages, edition.number_of_pages.map(String.init))
                    field(\.isbn13, edition.isbn_13?.joined(separator: ", "))
                    field(\.isbn10, edition.isbn_10?.joined(separator: ", "))
                    field(\.languages, edition.languages?.map { reference in
                        let code = reference.key.components(separatedBy: "/").last ?? ""
                        return Locale.current.localizedString(forLanguageCode: code) ?? code
                    }.joined(separator: ", "))
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(\.twenty)
        }
        .navigationTitle(\.editionDetailsTitle).navigationBarTitleDisplayMode(.inline)
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

    private func field(_ titleKeyPath: KeyPath<ShowBookStrings, String>, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: \.four) {
            Text(titleKeyPath).font(\.headline)
            if let value, !value.isEmpty {
                Text(value).font(\.body).textSelection(.enabled)
            } else {
                Text(\.detailsNotAvailable).font(\.body).textSelection(.enabled)
            }
        }
    }
}
