import XCTest
import SwiftUI
import SnapshotTestKit
@testable import ShowBook

private final class SubjectFixtureProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var offline = false
    static func setOffline(_ value: Bool) { lock.lock(); defer { lock.unlock() }; offline = value }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() {
        Self.lock.lock(); let offline = Self.offline; Self.lock.unlock()
        if offline { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)); return }
        XCTAssertEqual(request.url?.path, "/search.json")
        let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(query.first { $0.name == "q" }?.value, "subject:fiction")
        XCTAssertTrue(query.first { $0.name == "fields" }?.value?.contains("ratings_average,ratings_count") == true)
        let body = #"{"docs":[{"key":"/works/OL1W","title":"First","author_name":["Author"],"cover_i":123,"ratings_average":4.25,"ratings_count":24},{"key":"/works/OL1W","title":"Duplicate"},{"key":"/books/OL1M","title":"Wrong resource"}]}"#
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
}

final class DiscoverServiceTests: XCTestCase {
    func testSubjectMappingAndOfflineCacheAfterRecreation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory); SubjectFixtureProtocol.setOffline(false) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SubjectFixtureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        SubjectFixtureProtocol.setOffline(false)
        let service = DiscoverService(session: session, directory: directory)
        let result = try await service.load(.fiction)
        XCTAssertFalse(result.cached)
        XCTAssertEqual(result.books.count, 1)
        XCTAssertEqual(result.books.first?.key, "/works/OL1W")
        XCTAssertEqual(result.books.first?.authorName, ["Author"])
        XCTAssertEqual(result.books.first?.coverI, 123)
        XCTAssertEqual(result.books.first?.availableRating?.average, 4.25)
        XCTAssertEqual(result.books.first?.availableRating?.count, 24)
        SubjectFixtureProtocol.setOffline(true)
        let reopened = DiscoverService(session: session, directory: directory)
        let cached = try await reopened.load(.fiction, refresh: true)
        XCTAssertTrue(cached.cached)
        XCTAssertEqual(cached.books.map(\.title), ["First"])
        XCTAssertEqual(cached.books.first?.availableRating?.average, 4.25)
        XCTAssertEqual(cached.books.first?.availableRating?.count, 24)
        do {
            _ = try await reopened.load(.history, refresh: true)
            XCTFail("A different category must not reuse fiction's cache")
        } catch { XCTAssertTrue(error is URLError) }
    }

    func testSubjectFieldsCanBeAbsentAndMalformedDataIsRejected() throws {
        let response = try JSONDecoder().decode(BooksResponse.self, from: Data(#"{"docs":[{"key":"/works/OL2W","title":"Minimal"}]}"#.utf8))
        XCTAssertNil(response.docs.first?.authorName)
        XCTAssertNil(response.docs.first?.coverI)
        XCTAssertNil(response.docs.first?.availableRating)
        XCTAssertThrowsError(try JSONDecoder().decode(BooksResponse.self, from: Data(#"{"docs":"invalid"}"#.utf8)))
    }
}

#if DEBUG
@MainActor final class DeveloperDiscoverRenderingTests: XCTestCase {
    func testDeveloperLaunchAndDiscoverVariantsRender() async throws {
        let defaults = UserDefaults.standard
        let keys = ["developer.source", "developer.scenario", "developer.discoverVariant"]
        let originals = keys.map { defaults.object(forKey: $0) }
        defer { for (key, value) in zip(keys, originals) { defaults.set(value, forKey: key) } }
        defaults.set("stub", forKey: "developer.source")
        defaults.set("success", forKey: "developer.scenario")
        try await capture(NavigationStack { DeveloperSettingsView(onContinue: {}, cacheSummaryOverride: "0 queries (0 KB)") }, name: "developer-launch")
        defaults.set("A", forKey: "developer.discoverVariant")
        try await capture(NavigationStack { DiscoverView(model: DiscoverViewModel(service: GoldenDiscoverFixture())) }, name: "discover-list")
        defaults.set("B", forKey: "developer.discoverVariant")
        try await capture(NavigationStack { DiscoverView(model: DiscoverViewModel(service: GoldenDiscoverFixture())) }, name: "discover-grid")
    }
    private func capture<V: View>(_ view: V, name: String) async throws {
        try await PortfolioSnapshot.assertVariants(view, named: name, file: #filePath)
    }
}
private actor GoldenDiscoverFixture: DiscoverServing {
    func load(_ category: DiscoverCategory, refresh: Bool) async throws -> DiscoverResult {
        let url = try XCTUnwrap(URL(string: "https://openlibrary.org/search.json"))
        let body = try XCTUnwrap(DeveloperStubProtocol.body(for: url))
        let response = try JSONDecoder().decode(BooksResponse.self, from: Data(body.utf8))
        return DiscoverResult(books: response.docs, cached: false, savedAt: Date(timeIntervalSince1970: 0))
    }
}
#endif
