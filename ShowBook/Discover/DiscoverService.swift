import Foundation
import Combine
import CommonNetworking

enum DiscoverCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case fiction, mystery, science, history
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct SubjectResponse: Decodable {
    let works: [Work]
    struct Work: Decodable {
        let key: String
        let title: String
        let authors: [Author]?
        let cover_id: Int?
        struct Author: Decodable { let name: String }
        var book: Book {
            Book(title: title, ratingsAverage: nil, ratingsCount: nil,
                 authorName: authors?.map(\.name), coverI: cover_id, image: nil, key: key)
        }
    }
}

struct DiscoverResult {
    let books: [Book]
    let cached: Bool
    let savedAt: Date
}

/// Bounded to four subject files per environment. Cache data never crosses live/stub boundaries.
actor DiscoverService {
    static let shared = DiscoverService()
    private let session: URLSession?
    private let directory: URL
    private var nextRequest = Date.distantPast
    private struct Snapshot: Codable { let savedAt: Date; let books: [Book] }
    init(session: URLSession? = nil, directory: URL? = nil) {
        self.session = session
        self.directory = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Discover-v1", isDirectory: true)
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
            components.path = "/subjects/\(category.rawValue).json"
            components.queryItems = [.init(name: "limit", value: "12")]
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
            let decoded = try JSONDecoder().decode(SubjectResponse.self, from: response.data)
            var keys = Set<String>()
            let books = decoded.works.filter {
                BookDetailsService.validKey($0.key, resource: "works") && keys.insert($0.key).inserted
            }.prefix(12).map(\.book)
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

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published private(set) var books: [Book] = []
    @Published private(set) var loading = false
    @Published private(set) var message: String?
    @Published private(set) var cachedAt: Date?
    private var requestID = UUID()
    private let service: DiscoverService
    init(service: DiscoverService = .shared) { self.service = service }
    func load(_ category: DiscoverCategory, refresh: Bool = false) async {
        let id = UUID(); requestID = id
        loading = true; message = nil; cachedAt = nil; books = []
        defer { if requestID == id { loading = false } }
        do {
            let result = try await service.load(category, refresh: refresh)
            guard requestID == id, !Task.isCancelled else { return }
            books = result.books
            cachedAt = result.cached ? result.savedAt : nil
        } catch {
            guard requestID == id, !Task.isCancelled else { return }
            message = "Couldn’t load this category. Check your connection and try again."
        }
    }
}
