import Foundation
import CommonNetworking

struct LibraryText: Decodable, Sendable {
    let value: String
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) { value = text }
        else { value = try container.decode(TextValue.self).value }
    }
    private struct TextValue: Decodable { let value: String }
}
struct LibraryWork: Decodable, Sendable {
    let key: String
    let title: String
    let description: LibraryText?
    let subjects: [String]?
    let covers: [Int]?
    let first_publish_date: String?
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
    struct Reference: Decodable, Sendable { let key: String }
}
struct LibraryEditions: Decodable, Sendable {
    let size: Int
    let entries: [LibraryEdition]
}
protocol BookDetailsServing: Sendable {
    func work(key: String) async throws -> LibraryWork
    func editions(key: String, offset: Int) async throws -> LibraryEditions
    func edition(key: String) async throws -> LibraryEdition
}

enum BookDetailsError: LocalizedError {
    case invalidKey
    var errorDescription: String? { "This book has no valid Open Library identifier. Search for it again to open online details." }
}

/// App-owned endpoints. HTTP transport stays in CommonNetworking.
actor BookDetailsService: BookDetailsServing {
    static let shared = BookDetailsService()
    private let client: CommonNetworking.HTTPClient
    private var nextRequest = Date.distantPast
    private var cache: [URL: (Date, Data)] = [:]
    static let pageSize = 20

    init(session: URLSession = .shared) {
        #if DEBUG
        client = CommonNetworking.HTTPClient(session: session, logger: .console)
        #else
        client = CommonNetworking.HTTPClient(session: session)
        #endif
    }
    static func validKey(_ key: String, resource: String) -> Bool {
        let suffix = resource == "works" ? "W" : "M"
        return key.range(of: "^/\(resource)/OL[0-9]+\(suffix)$", options: .regularExpression) != nil
    }
    func work(key: String) async throws -> LibraryWork { try await fetch(key: key, resource: "works") }
    func edition(key: String) async throws -> LibraryEdition { try await fetch(key: key, resource: "books") }
    func editions(key: String, offset: Int) async throws -> LibraryEditions {
        try await fetch(key: key, resource: "works", editionsOffset: offset)
    }
    private func fetch<T: Decodable & Sendable>(key: String, resource: String, editionsOffset: Int? = nil) async throws -> T {
        try Task.checkCancellation()
        guard Self.validKey(key, resource: resource) else { throw BookDetailsError.invalidKey }
        var components = URLComponents(string: "https://openlibrary.org")!
        components.path = key + (editionsOffset == nil ? ".json" : "/editions.json")
        if let offset = editionsOffset {
            components.queryItems = [.init(name: "limit", value: String(Self.pageSize)), .init(name: "offset", value: String(max(0, offset)))]
        }
        let url = components.url!
        if let (expiry, data) = cache[url], expiry > Date() {
            return try JSONDecoder().decode(T.self, from: data)
        }
        // Reserve slots before suspension so concurrent detail requests stay paced.
        let slot = max(Date(), nextRequest)
        nextRequest = slot.addingTimeInterval(0.4)
        let wait = slot.timeIntervalSinceNow
        if wait > 0 { try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
        try Task.checkCancellation()
        var request = URLRequest(url: url)
        request.setValue("ShowBook (anuragchourasia1999@gmail.com)", forHTTPHeaderField: "User-Agent")
        let result = try await client.send(request)
        try Task.checkCancellation()
        guard (200..<300).contains(result.statusCode) else { throw HTTPClientError.unsuccessfulStatus(result) }
        let decoded = try JSONDecoder().decode(T.self, from: result.data)
        cache = cache.filter { $0.value.0 > Date() }
        if cache.count >= 100 { cache.removeAll() }
        cache[url] = (Date().addingTimeInterval(300), result.data)
        return decoded
    }
}
