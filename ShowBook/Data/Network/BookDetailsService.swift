import Foundation
import CommonNetworkingKit

protocol BookDetailsServing: BookDetailsRepositoryProtocol {}

/// App-owned endpoints. HTTP transport stays in CommonNetworkingKit.
actor BookDetailsService: BookDetailsServing {
    static let shared = BookDetailsService()
    private let session: URLSession?
    private var nextRequest = Date.distantPast
    private var cache: [String: (Date, Data)] = [:]
    static let pageSize = 20

    init(session: URLSession? = nil) { self.session = session }
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
        let context = AppNetworking.context(session: session)
        let cacheKey = context.namespace + url.absoluteString
        let client = context.client
        if let (expiry, data) = cache[cacheKey], expiry > Date() {
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
        guard (200..<300).contains(result.statusCode) else {
            switch result.statusCode {
            case 404: throw BookDetailsError.notFound
            case 429: throw BookDetailsError.rateLimited
            default: throw BookDetailsError.serverError(statusCode: result.statusCode)
            }
        }
        do {
            let decoded = try JSONDecoder().decode(T.self, from: result.data)
            cache = cache.filter { $0.value.0 > Date() }
            if cache.count >= 100 { cache.removeAll() }
            cache[cacheKey] = (Date().addingTimeInterval(300), result.data)
            return decoded
        } catch {
            throw BookDetailsError.unreadable
        }
    }
}
