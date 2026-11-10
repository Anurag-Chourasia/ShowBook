//
//  BookDetailsEntities.swift
//  ShowBook
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

struct LibraryEdition: Decodable, Sendable, Identifiable {
    let key: String
    let title: String
    let publishers: [String]?
    let publish_date: String?
    let number_of_pages: Int?
    let physical_format: String?
    let isbn_10: [String]?
    let isbn_13: [String]?
    let languages: [Reference]?
    let covers: [Int]?
    var id: String { key }

    struct Reference: Decodable, Sendable {
        let key: String
        init(key: String) { self.key = key }
    }

    init(
        key: String,
        title: String,
        publishers: [String]? = nil,
        publish_date: String? = nil,
        number_of_pages: Int? = nil,
        physical_format: String? = nil,
        isbn_10: [String]? = nil,
        isbn_13: [String]? = nil,
        languages: [Reference]? = nil,
        covers: [Int]? = nil
    ) {
        self.key = key
        self.title = title
        self.publishers = publishers
        self.publish_date = publish_date
        self.number_of_pages = number_of_pages
        self.physical_format = physical_format
        self.isbn_10 = isbn_10
        self.isbn_13 = isbn_13
        self.languages = languages
        self.covers = covers
    }
}

struct LibraryEditions: Decodable, Sendable {
    let size: Int
    let entries: [LibraryEdition]

    init(size: Int, entries: [LibraryEdition]) {
        self.size = size
        self.entries = entries
    }
}

enum BookDetailsError: LocalizedError, Sendable {
    case invalidKey
    case notFound
    case rateLimited
    case serverError(statusCode: Int)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "This book has no valid Open Library identifier. Search for it again to open online details."
        case .notFound:
            return "This book's details are no longer available from Open Library."
        case .rateLimited:
            return "Open Library is busy. Please wait a moment and try again."
        case .serverError:
            return "Open Library was unable to return this book's record. Please try again."
        case .unreadable:
            return "Open Library returned details in an unreadable format."
        }
    }
}
