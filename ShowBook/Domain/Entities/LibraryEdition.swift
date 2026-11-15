import Foundation

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
