//
//  BookSearchRepositoryProtocol.swift
//  ShowBook
//

import Foundation

protocol BookSearchRepositoryProtocol: Sendable {
    func searchBooks(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) -> Task<Void, Never>?
}
