import Foundation
import Combine
import CommonNetworking

@MainActor final class BookDetailsViewModel: ObservableObject {
    @Published private(set) var work: LibraryWork?
    @Published private(set) var editions: [LibraryEdition] = []
    @Published private(set) var loading = false
    @Published private(set) var loadingEditions = false
    @Published private(set) var error: String?
    @Published private(set) var editionsError: String?
    @Published private(set) var hasMoreEditions = true
    private var offset = 0
    private let key: String?
    private let service: any BookDetailsServing

    init(key: String?, service: any BookDetailsServing = BookDetailsService.shared) {
        self.key = key
        self.service = service
    }
    func load() async {
        guard !loading else { return }
        guard let key else { error = BookDetailsError.invalidKey.localizedDescription; return }
        loading = true
        error = nil
        defer { loading = false }
        do {
            if work == nil {
                let result = try await service.work(key: key)
                try Task.checkCancellation()
                work = result
            }
            if editions.isEmpty { await loadMoreEditions() }
        } catch is CancellationError { }
        catch { if !Task.isCancelled { self.error = Self.message(error) } }
    }
    func loadMoreEditions() async {
        guard let key, !loadingEditions, hasMoreEditions else { return }
        loadingEditions = true
        editionsError = nil
        defer { loadingEditions = false }
        do {
            let page = try await service.editions(key: key, offset: offset)
            try Task.checkCancellation()
            var seen = Set(editions.map(\.key))
            editions.append(contentsOf: page.entries.filter { seen.insert($0.key).inserted })
            offset += page.entries.count
            hasMoreEditions = !page.entries.isEmpty && offset < page.size
        } catch is CancellationError { }
        catch { if !Task.isCancelled { editionsError = Self.message(error) } }
    }
    static func message(_ error: Error) -> String {
        if let error = error as? BookDetailsError { return error.localizedDescription }
        if case HTTPClientError.unsuccessfulStatus(let response) = error {
            switch response.statusCode {
            case 404: return "This record is no longer available on Open Library."
            case 429: return "Open Library is busy. Please wait a moment and retry."
            default: return "Open Library could not load this record. Please try again."
            }
        }
        if error is DecodingError { return "This record could not be read. Please try again later." }
        return "Unable to load details. Check your connection and retry."
    }
}
