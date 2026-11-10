//
//  FetchBookDetailsUseCase.swift
//  ShowBook
//

import Foundation

protocol FetchBookDetailsUseCaseProtocol: Sendable {
    func execute(key: String) async throws -> LibraryWork
}

final class FetchBookDetailsUseCase: FetchBookDetailsUseCaseProtocol {
    private let repository: any BookDetailsRepositoryProtocol

    init(repository: any BookDetailsRepositoryProtocol) {
        self.repository = repository
    }

    func execute(key: String) async throws -> LibraryWork {
        try await repository.work(key: key)
    }
}
