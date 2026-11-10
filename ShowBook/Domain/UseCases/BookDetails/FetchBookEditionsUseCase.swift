//
//  FetchBookEditionsUseCase.swift
//  ShowBook
//

import Foundation

protocol FetchBookEditionsUseCaseProtocol: Sendable {
    func execute(key: String, offset: Int) async throws -> LibraryEditions
}

final class FetchBookEditionsUseCase: FetchBookEditionsUseCaseProtocol {
    private let repository: any BookDetailsRepositoryProtocol

    init(repository: any BookDetailsRepositoryProtocol) {
        self.repository = repository
    }

    func execute(key: String, offset: Int) async throws -> LibraryEditions {
        try await repository.editions(key: key, offset: offset)
    }
}
