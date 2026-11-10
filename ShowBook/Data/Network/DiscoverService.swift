import Foundation
import Combine
import CommonNetworkingKit

/// Bounded to four subject files per environment. Cache data never crosses live/stub boundaries.
protocol DiscoverServing: DiscoverRepositoryProtocol {
    func load(_ category: DiscoverCategory, refresh: Bool) async throws -> DiscoverResult
}

extension DiscoverServing {
    func loadCategory(_ category: DiscoverCategory, refresh: Bool) async throws -> DiscoverResult {
        try await load(category, refresh: refresh)
    }
}

actor DiscoverService: DiscoverServing {
    static let shared = DiscoverService()
    private let session: URLSession?
    private let directory: URL
    private var nextRequest = Date.distantPast
    private struct Snapshot: Codable { let savedAt: Date; let books: [Book] }
    init(session: URLSession? = nil, directory: URL? = nil) {
        self.session = session
        self.directory = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Discover-v2", isDirectory: true)
    }
    func load(_ category: DiscoverCategory, refresh: Bool = false) async throws -> DiscoverResult {
        let context = AppNetworking.context(session: session)
        let namespace = context.namespace
        let file = directory.appendingPathComponent(namespace + "-" + category.rawValue + ".json")
        let saved = (try? Data(contentsOf: file)).flatMap { try? JSONDecoder().decode(Snapshot.self, from: $0) }
        if !refresh, let saved, Date().timeIntervalSince(saved.savedAt) < 86_400 {
            return DiscoverResult(books: saved.books, cached: true, savedAt: saved.savedAt)
        }
        do {
            var components = URLComponents(string: "https://openlibrary.org")!
            components.path = "/search.json"
            components.queryItems = [
                .init(name: "q", value: "subject:\(category.rawValue)"),
                .init(name: "limit", value: "12"),
                .init(name: "fields", value: "key,title,author_name,cover_i,ratings_average,ratings_count")
            ]
            var request = URLRequest(url: components.url!)
            request.setValue("ShowBook (anuragchourasia1999@gmail.com)", forHTTPHeaderField: "User-Agent")
            let slot = max(Date(), nextRequest)
            nextRequest = slot.addingTimeInterval(0.4)
            let wait = slot.timeIntervalSinceNow
            if wait > 0 { try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
            try Task.checkCancellation()
            let response = try await context.client.send(request)
            try Task.checkCancellation()
            guard (200..<300).contains(response.statusCode) else { throw HTTPClientError.unsuccessfulStatus(response) }
            let decoded = try JSONDecoder().decode(BooksResponse.self, from: response.data)
            var keys = Set<String>()
            let books = decoded.docs.filter {
                BookDetailsService.validKey($0.key ?? "", resource: "works") && keys.insert($0.key ?? "").inserted
            }.prefix(12).map { $0 }
            let snapshot = Snapshot(savedAt: Date(), books: books)
            // Cache failure must not discard a successful response.
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if let data = try? JSONEncoder().encode(snapshot) { try? data.write(to: file, options: .atomic) }
            return DiscoverResult(books: books, cached: false, savedAt: snapshot.savedAt)
        } catch {
            if Task.isCancelled || error is CancellationError { throw CancellationError() }
            if let saved { return DiscoverResult(books: saved.books, cached: true, savedAt: saved.savedAt) }
            throw error
        }
    }
}
