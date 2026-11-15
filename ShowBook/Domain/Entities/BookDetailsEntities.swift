//
//  BookDetailsEntities.swift
//  ShowBook
//
//

import Foundation

struct LibraryText: Decodable, Sendable {
    let value: String
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) { value = text }
        else { value = try container.decode(TextValue.self).value }
    }
    init(value: String) { self.value = value }
    private struct TextValue: Decodable { let value: String }
}

struct LibraryWork: Decodable, Sendable {
    let key: String
    let title: String
    let description: LibraryText?
    let subjects: [String]?
    let covers: [Int]?
    let first_publish_date: String?

    init(
        key: String,
        title: String,
        description: LibraryText? = nil,
        subjects: [String]? = nil,
        covers: [Int]? = nil,
        first_publish_date: String? = nil
    ) {
        self.key = key
        self.title = title
        self.description = description
        self.subjects = subjects
        self.covers = covers
        self.first_publish_date = first_publish_date
    }
}
