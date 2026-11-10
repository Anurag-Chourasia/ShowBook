//
//  FetchDiscoverCategoryUseCase.swift
//  ShowBook
//

import Foundation

protocol FetchDiscoverCategoryUseCaseProtocol: Sendable {
    func execute(category: DiscoverCategory, refresh: Bool) async throws -> DiscoverResult
}

final class FetchDiscoverCategoryUseCase: FetchDiscoverCategoryUseCaseProtocol {
    private let repository: any DiscoverRepositoryProtocol

    init(repository: any DiscoverRepositoryProtocol) {
        self.repository = repository
    }

    func execute(category: DiscoverCategory, refresh: Bool) async throws -> DiscoverResult {
        try await repository.loadCategory(category, refresh: refresh)
    }
}
