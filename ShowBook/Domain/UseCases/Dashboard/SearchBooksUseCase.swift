//
//  SearchBooksUseCase.swift
//  ShowBook
//

import Foundation

protocol SearchBooksUseCaseProtocol: Sendable {
    func execute(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) -> Task<Void, Never>?
}

final class SearchBooksUseCase: SearchBooksUseCaseProtocol {
    private let repository: any BookSearchRepositoryProtocol

    init(repository: any BookSearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) -> Task<Void, Never>? {
        repository.searchBooks(title: title, offset: offset, completion: completion)
    }
}
