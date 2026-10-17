import XCTest
import SwiftUI
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
        try await capture(AppLaunchView().environmentObject(UserViewModel()), name: "developer-launch")
        try await capture(AppLaunchView().environmentObject(UserViewModel()).environment(\.colorScheme, .dark), name: "developer-launch-dark")
        defaults.set("A", forKey: "developer.discoverVariant")
        try await capture(NavigationStack { DiscoverView() }.environment(\.colorScheme, .dark), name: "discover-list-dark")
        defaults.set("B", forKey: "developer.discoverVariant")
        try await capture(NavigationStack { DiscoverView() }, name: "discover-grid")
        try await capture(NavigationStack { DiscoverView() }.environment(\.dynamicTypeSize, .accessibility3), name: "discover-grid-accessibility-fallback")
    }
    private func capture<V: View>(_ view: V, name: String) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        try await Task.sleep(nanoseconds: 800_000_000)
        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            XCTAssertTrue(window.drawHierarchy(in: window.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image); attachment.name = name
        attachment.lifetime = .keepAlways; add(attachment)
    }
}
#endif
