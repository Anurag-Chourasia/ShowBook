import XCTest
@testable import Adapter

final class DeveloperRuntimeTests: XCTestCase {
    func testRuntimePolicyAndStubScenarios() async throws {
        let keys = ["source", "scenario", "discover", "coverPreview", "ratings", "discoverVariant", "version", "build", "httpLogs"]
        let defaults = UserDefaults.standard
        let original = keys.map { defaults.object(forKey: "developer." + $0) }
        defer {
            for (key, value) in zip(keys, original) { defaults.set(value, forKey: "developer." + key) }
        }
        defaults.set("stub", forKey: "developer.source")
        defaults.set("success", forKey: "developer.scenario")
        for key in ["discover", "coverPreview", "ratings"] { defaults.set(false, forKey: "developer." + key) }
        defaults.set("B", forKey: "developer.discoverVariant")
        defaults.set("99.0", forKey: "developer.version")
        defaults.set("999", forKey: "developer.build")
        defaults.set(false, forKey: "developer.httpLogs")
        #if DEBUG
        XCTAssertFalse(AppRuntime.discoverEnabled)
        XCTAssertFalse(AppRuntime.coverPreviewEnabled)
        XCTAssertFalse(AppRuntime.ratingsEnabled)
        XCTAssertTrue(AppRuntime.discoverGrid)
        XCTAssertEqual(AppRuntime.version, "99.0")
        XCTAssertEqual(AppRuntime.build, "999")
        let url = URL(string: "https://openlibrary.org/search.json")!
        let captured = AppNetworking.context()
        defaults.set("empty", forKey: "developer.scenario")
        XCTAssertEqual(captured.namespace, "stub-success")
        var response = try await captured.client.send(URLRequest(url: url))
        XCTAssertEqual(try JSONDecoder().decode(BooksResponse.self, from: response.data).docs.count, 1)
        defaults.set("empty", forKey: "developer.scenario")
        response = try await AppNetworking.client().send(URLRequest(url: url))
        XCTAssertTrue(try JSONDecoder().decode(BooksResponse.self, from: response.data).docs.isEmpty)
        defaults.set("offline", forKey: "developer.scenario")
        do {
            _ = try await AppNetworking.client().send(URLRequest(url: url))
            XCTFail("Offline stub must fail")
        } catch let error as URLError { XCTAssertEqual(error.code, .notConnectedToInternet) }
        defaults.set("../../invalid", forKey: "developer.scenario")
        XCTAssertEqual(AppRuntime.cacheNamespace, "stub-success")
        #else
        XCTAssertTrue(AppRuntime.discoverEnabled)
        XCTAssertTrue(AppRuntime.coverPreviewEnabled)
        XCTAssertTrue(AppRuntime.ratingsEnabled)
        XCTAssertFalse(AppRuntime.discoverGrid)
        XCTAssertNil(AppRuntime.stubScenario)
        XCTAssertEqual(AppRuntime.cacheNamespace, "live")
        XCTAssertEqual(AppRuntime.version, AppRuntime.actualVersion)
        XCTAssertEqual(AppRuntime.build, AppRuntime.actualBuild)
        #endif
    }
}
