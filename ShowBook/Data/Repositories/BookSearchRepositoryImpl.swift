//
//  BookSearchRepositoryImpl.swift
//  ShowBook
//

import Foundation

final class BookSearchRepositoryImpl: BookSearchRepositoryProtocol {
    private let api: NetworkClass
    private let cache: BookCatalogCache

    init(api: NetworkClass = NetworkClass(), cache: BookCatalogCache = BookCatalogCache()) {
        self.api = api
        self.cache = cache
    }

    func searchBooks(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) -> Task<Void, Never>? {
        api.fetchBooks(title: title, offset: offset) { [cache] result in
            switch result {
            case .success(let books):
                cache.save(books: books, for: title, offset: offset)
                completion(.success(books))
            case .failure(let error):
                if let cached = cache.load(for: title, offset: offset), !cached.isEmpty {
                    completion(.success(cached))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}
