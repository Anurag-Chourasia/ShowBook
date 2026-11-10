import LocalizationKit
import Foundation
import Combine
import CommonNetworkingKit

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
    private let fetchBookDetailsUseCase: any FetchBookDetailsUseCaseProtocol
    private let fetchBookEditionsUseCase: any FetchBookEditionsUseCaseProtocol

    init(
        key: String?,
        fetchBookDetailsUseCase: (any FetchBookDetailsUseCaseProtocol)? = nil,
        fetchBookEditionsUseCase: (any FetchBookEditionsUseCaseProtocol)? = nil,
        service: any BookDetailsServing = BookDetailsService()
    ) {
        self.key = key
        self.service = service
        self.fetchBookDetailsUseCase = fetchBookDetailsUseCase ?? FetchBookDetailsUseCase(repository: service)
        self.fetchBookEditionsUseCase = fetchBookEditionsUseCase ?? FetchBookEditionsUseCase(repository: service)
    }

    #if DEBUG
    convenience init(key: String?) {
        self.init(key: key, service: BookDetailsService())
    }
    #endif
    func load() async {
        guard !loading else { return }
        guard let key else { error = BookDetailsError.invalidKey.localizedDescription; return }
        loading = true
        error = nil
        defer { loading = false }
        do {
            if work == nil {
                let result = try await fetchBookDetailsUseCase.execute(key: key)
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
            let page = try await fetchBookEditionsUseCase.execute(key: key, offset: offset)
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
            case 404: return String(\ShowBookStrings.errorNotFound)
            case 429: return String(\ShowBookStrings.errorBusy)
            default: return String(\ShowBookStrings.errorRecordFailed)
            }
        }
        if error is DecodingError { return String(\ShowBookStrings.errorUnreadable) }
        return String(\ShowBookStrings.errorDetailsFailed)
    }
}
