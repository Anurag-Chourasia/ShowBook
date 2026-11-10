import LocalizationKit
import Foundation
import Combine

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
    private let fetchBookDetailsUseCase: any FetchBookDetailsUseCaseProtocol
    private let fetchBookEditionsUseCase: any FetchBookEditionsUseCaseProtocol

    init(
        key: String?,
        fetchBookDetailsUseCase: (any FetchBookDetailsUseCaseProtocol)? = nil,
        fetchBookEditionsUseCase: (any FetchBookEditionsUseCaseProtocol)? = nil,
        service: (any BookDetailsRepositoryProtocol)? = nil
    ) {
        self.key = key
        let repo = service ?? BookDetailsService.shared
        self.fetchBookDetailsUseCase = fetchBookDetailsUseCase ?? FetchBookDetailsUseCase(repository: repo)
        self.fetchBookEditionsUseCase = fetchBookEditionsUseCase ?? FetchBookEditionsUseCase(repository: repo)
    }

    #if DEBUG
    convenience init(key: String?) {
        self.init(key: key, service: BookDetailsService())
    }
    #endif
    func load() async {
        guard !loading else { return }
        guard let key else { error = String(\.errorNoIdentifier); return }
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
        if let detailsError = error as? BookDetailsError {
            switch detailsError {
            case .invalidKey:
                return String(\.errorNoIdentifier)
            case .notFound:
                return String(\ShowBookStrings.errorNotFound)
            case .rateLimited:
                return String(\.errorBusy)
            case .serverError:
                return String(\.errorRecordFailed)
            case .unreadable:
                return String(\.errorUnreadable)
            }
        }
        let desc = String(describing: error)
        if desc.contains("404") { return String(\ShowBookStrings.errorNotFound) }
        if desc.contains("429") { return String(\.errorBusy) }
        if desc.contains("unsuccessfulStatus") { return String(\.errorRecordFailed) }
        if error is DecodingError { return String(\.errorUnreadable) }
        return String(\.errorDetailsFailed)
    }
}
