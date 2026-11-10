//
//  DiscoverEntities.swift
//  ShowBook
//

import Foundation

enum DiscoverCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case fiction, mystery, science, history
    var id: String { rawValue }
}

struct DiscoverResult: Sendable {
    let books: [Book]
    let cached: Bool
    let savedAt: Date

    init(books: [Book], cached: Bool, savedAt: Date) {
        self.books = books
        self.cached = cached
        self.savedAt = savedAt
    }
}
