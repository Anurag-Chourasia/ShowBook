//
//  FetchBookmarksUseCase.swift
//  ShowBook
//

import Foundation

protocol FetchBookmarksUseCaseProtocol: Sendable {
    func execute() -> [Book]
}

final class FetchBookmarksUseCase: FetchBookmarksUseCaseProtocol {
    private let repository: any BookmarkRepositoryProtocol

    init(repository: any BookmarkRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> [Book] {
        repository.fetchBooks()
    }
}
