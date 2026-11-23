import Foundation
import CommonNetworkingKit
import FoundationKit

protocol BookDetailsServing: BookDetailsRepositoryProtocol {}

/// App-owned endpoints. HTTP transport stays in CommonNetworkingKit.
actor BookDetailsService: BookDetailsServing {
    static let shared = BookDetailsService()
    private let session: URLSession?
    private let clock: any AppClock
    private var nextRequest = Date.distantPast
    private var cache: [String: (Date, Data)] = [:]
    static let pageSize = 20
    private let cacheDirectory: URL? = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("BookDetailsCache", isDirectory: true)
        if let dir { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }()

    init(session: URLSession? = nil, clock: any AppClock = SystemClock()) {
        self.session = session
        self.clock = clock
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
    private func fetch<T: Decodable & Sendable>(
        key: String,
        resource: String,
        editionsOffset: Int? = nil
    ) async throws -> T {
        try Task.checkCancellation()
        guard Self.validKey(key, resource: resource) else { throw BookDetailsError.invalidKey }
        var components = URLComponents(string: "https://openlibrary.org")!
        components.path = key + (editionsOffset == nil ? ".json" : "/editions.json")
        if let offset = editionsOffset {
            components.queryItems = [
                .init(name: "limit", value: String(Self.pageSize)),
                .init(name: "offset", value: String(max(0, offset)))
            ]
        }
        let url = components.url!
        let context = AppNetworking.context(session: session)
        let cacheKey = context.namespace + url.absoluteString
        if let (expiry, data) = cache[cacheKey], expiry > clock.now {
            return try JSONDecoder().decode(T.self, from: data)
        }
        if let diskData = readDisk(for: cacheKey),
           let cached = try? JSONDecoder().decode(T.self, from: diskData) {
            cache[cacheKey] = (clock.now.addingTimeInterval(3600), diskData)
            return cached
        }
        return try await fetchRemote(url: url, cacheKey: cacheKey, client: context.client)
    }
    private func fetchRemote<T: Decodable & Sendable>(
        url: URL,
        cacheKey: String,
        client: HTTPClient
    ) async throws -> T {
        let now = clock.now
        let slot = max(now, nextRequest)
        nextRequest = slot.addingTimeInterval(0.4)
        let wait = slot.timeIntervalSince(now)
        if wait > 0 { try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
        try Task.checkCancellation()
        var request = URLRequest(url: url)
        request.setValue("ShowBook (anuragchourasia1999@gmail.com)", forHTTPHeaderField: "User-Agent")
        do {
            let result = try await client.send(request)
            try Task.checkCancellation()
            guard (200..<300).contains(result.statusCode) else {
                switch result.statusCode {
                case 404: throw BookDetailsError.notFound
                case 429: throw BookDetailsError.rateLimited
                default: throw BookDetailsError.serverError(statusCode: result.statusCode)
                }
            }
            let decoded = try JSONDecoder().decode(T.self, from: result.data)
            cache[cacheKey] = (clock.now.addingTimeInterval(3600), result.data)
            writeDisk(data: result.data, for: cacheKey)
            return decoded
        } catch {
            if let disk = readDisk(for: cacheKey), let cached = try? JSONDecoder().decode(T.self, from: disk) {
                return cached
            }
            if let detailsErr = error as? BookDetailsError { throw detailsErr }
            throw BookDetailsError.unreadable
        }
    }
    private func readDisk(for key: String) -> Data? {
        let safe = key.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        guard let url = cacheDirectory?.appendingPathComponent(safe + ".json") else { return nil }
        return try? Data(contentsOf: url)
    }
    private func writeDisk(data: Data, for key: String) {
        let safe = key.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        guard let url = cacheDirectory?.appendingPathComponent(safe + ".json") else { return }
        try? data.write(to: url, options: .atomic)
    }
}
