import XCTest
@testable import ShowBook

#if DEBUG
final class DeveloperFixtureResourceTests: XCTestCase {
    private func payload(_ type: DeveloperStubProtocol.Type, _ address: String) throws -> [String: Any] {
        let url = try XCTUnwrap(URL(string: address))
        let body = try XCTUnwrap(type.body(for: url))
        let data = try XCTUnwrap(body.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testAppBundleCatalogSuppliesAllScenarioRoutes() throws {
        let routes = [
            ("https://openlibrary.org/subjects/design.json", "works"),
            ("https://openlibrary.org/search.json", "docs"),
            ("https://openlibrary.org/works/OL1W/editions.json", "entries"),
            ("https://openlibrary.org/works/OL1W.json", "title"),
            ("https://openlibrary.org/books/OL1M.json", "title"),
            ("https://api.first.org/data/v1/countries", "data")
        ]
        let scenarios: [DeveloperStubProtocol.Type] = [DeveloperStubProtocol.self, EmptyStubProtocol.self, ShowcaseStubProtocol.self]
        for scenario in scenarios {
            for (address, key) in routes {
                XCTAssertNotNil(try payload(scenario, address)[key], "\(scenario.scenario): \(key)")
            }
        }
        let first = try payload(DeveloperStubProtocol.self, "https://openlibrary.org/search.json?offset=0")
        let next = try payload(DeveloperStubProtocol.self, "https://openlibrary.org/search.json?offset=100")
        XCTAssertEqual((first["docs"] as? [Any])?.count, 1)
        XCTAssertEqual((next["docs"] as? [Any])?.count, 0)
        let showcase = try payload(ShowcaseStubProtocol.self, "https://openlibrary.org/subjects/design.json")
        XCTAssertEqual((showcase["works"] as? [Any])?.count, 5)
        XCTAssertNil(DeveloperStubProtocol.body(for: try XCTUnwrap(URL(string: "https://example.invalid/"))))
    }

    func testOfflineTransportFailsWithoutUsingNetwork() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OfflineStubProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        do {
            _ = try await session.data(from: XCTUnwrap(URL(string: "https://openlibrary.org/search.json")))
            XCTFail("Offline transport must fail")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }
    }
}
#endif
