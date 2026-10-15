//
//  Models.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation

// MARK: - CountryModel
struct CountryModel: Codable {
    let status: String
    let statusCode: Int
    let version, access: String
    let total, offset, limit: Int
    let data: [String: Datum]
    
    enum CodingKeys: String, CodingKey {
        case status
        case statusCode = "status-code"
        case version, access, total, offset, limit, data
    }
}

// MARK: - Datum
struct Datum: Codable {
    let country: String
    let region: Region
}

// MARK: - Region
// Region names come from the service and are not a closed set.
struct Region: RawRepresentable, Codable, Hashable {
    let rawValue: String

    init(rawValue: String) { self.rawValue = rawValue }
    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static let africa = Region(rawValue: "Africa")
    static let antarctic = Region(rawValue: "Antarctic")
    static let asia = Region(rawValue: "Asia")
    static let centralAmerica = Region(rawValue: "Central America")
}

// MARK: - IPApiResponse
struct IPApiResponseModel: Codable {
    let status: String
    let country: String
    let countryCode: String
    let region: String
    let regionName: String
    let city: String
    let zip: String
    let lat: Double
    let lon: Double
    let timezone: String
    let isp: String
    let org: String
    let asDescription: String
    let query: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case country
        case countryCode
        case region
        case regionName
        case city
        case zip
        case lat
        case lon
        case timezone
        case isp
        case org
        case asDescription = "as"
        case query
    }
}

struct Book: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let ratingsAverage: Double?
    let ratingsCount: Int?
    let authorName: [String]?
    let coverI: Int?
    let image: Data?
    var key: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case title, key
        case ratingsAverage = "ratings_average"
        case ratingsCount = "ratings_count"
        case authorName = "author_name"
        case coverI = "cover_i"
        case image
    }
    
    // Implementing Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.ratingsAverage == rhs.ratingsAverage &&
        lhs.ratingsCount == rhs.ratingsCount &&
        lhs.authorName == rhs.authorName &&
        lhs.coverI == rhs.coverI &&
        lhs.image == rhs.image
    }
}

// MARK: - BooksResponse
struct BooksResponse: Codable {
    let docs: [Book]
}
