//
//  BookDetailsRepositoryProtocol.swift
//  ShowBook
//

import Foundation

protocol BookDetailsRepositoryProtocol: Sendable {
    func work(key: String) async throws -> LibraryWork
    func editions(key: String, offset: Int) async throws -> LibraryEditions
    func edition(key: String) async throws -> LibraryEdition
}
