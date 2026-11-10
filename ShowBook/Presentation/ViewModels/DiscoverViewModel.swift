//
//  DiscoverViewModel.swift
//  ShowBook
//

import Foundation
import Combine
import LocalizationKit

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published private(set) var books: [Book] = []
    @Published private(set) var loading = false
    @Published private(set) var message: String?
    @Published private(set) var cachedAt: Date?
    private var requestID = UUID()
    private let fetchDiscoverCategoryUseCase: any FetchDiscoverCategoryUseCaseProtocol

    init(
        fetchDiscoverCategoryUseCase: (any FetchDiscoverCategoryUseCaseProtocol)? = nil,
        service: (any DiscoverRepositoryProtocol)? = nil
    ) {
        let repo = service ?? DiscoverService.shared
        self.fetchDiscoverCategoryUseCase = fetchDiscoverCategoryUseCase ?? FetchDiscoverCategoryUseCase(repository: repo)
    }

    #if DEBUG
    convenience init() { self.init(service: DiscoverService.shared) }
    #endif

    func load(_ category: DiscoverCategory, refresh: Bool = false) async {
        let id = UUID()
        requestID = id
        loading = true
        message = nil
        cachedAt = nil
        books = []
        defer { if requestID == id { loading = false } }
        do {
            let result = try await fetchDiscoverCategoryUseCase.execute(category: category, refresh: refresh)
            guard requestID == id, !Task.isCancelled else { return }
            books = result.books
            cachedAt = result.cached ? result.savedAt : nil
        } catch {
            guard requestID == id, !Task.isCancelled else { return }
            message = String(\ShowBookStrings.errorCategoryFailed)
        }
    }
}
