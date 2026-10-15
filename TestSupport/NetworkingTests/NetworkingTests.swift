import Foundation
import XCTest
@testable import Adapter

private class FixtureProtocol: URLProtocol {
    class var status: Int { 200 }
    class var title: String { "Swift book" }
    class var failure: URLError.Code? { nil }
    class var malformed: Bool { false }
    class var empty: Bool { false }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
        if let failure = Self.failure { client?.urlProtocol(self, didFailWithError: URLError(failure)); return }
        let file: String
        switch request.url!.path {
        case "/data/v1/countries": file = "countries"
        case "/json": file = "ip"
        case "/search.json":
            file = "books"
            XCTAssertEqual(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems,
                [URLQueryItem(name: "title", value: Self.title), .init(name: "limit", value: "10"), .init(name: "offset", value: "20")])
        default: XCTFail("Unexpected request"); client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL)); return
        }
        let bytes = Self.empty ? Data() : Self.malformed ? Data("not json".utf8) : try! Data(contentsOf: Bundle.module.url(forResource: file, withExtension: "json")!)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: bytes)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
private final class PunctuationProtocol: FixtureProtocol {
    override class var title: String { "C++ & Swift? #1 = 50% / हिंदी" }
    override func startLoading() {
        if request.url?.path == "/search.json" {
            XCTAssertNil(request.url?.fragment)
            XCTAssertFalse(request.url!.absoluteString.contains("+"))
        }
        super.startLoading()
    }
}
private final class Non2xxProtocol: FixtureProtocol { override class var status: Int { 500 } }
private final class MalformedProtocol: FixtureProtocol { override class var malformed: Bool { true } }
private final class EmptyProtocol: FixtureProtocol { override class var empty: Bool { true }; override class var status: Int { 204 } }
private final class CancelledProtocol: FixtureProtocol { override class var failure: URLError.Code? { .cancelled } }
private final class OfflineProtocol: FixtureProtocol { override class var failure: URLError.Code? { .notConnectedToInternet } }

final class NetworkingTests: XCTestCase {
    private func check(_ fixture: FixtureProtocol.Type, success: Bool, transportError: URLError.Code? = nil) async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [fixture]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let api = NetworkClass(session: session)
        let countries = expectation(description: "countries once"); countries.assertForOverFulfill = true
        let ip = expectation(description: "IP once"); ip.assertForOverFulfill = true
        let books = expectation(description: "books once"); books.assertForOverFulfill = true
        api.fetchCountries { value, error in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertEqual(value != nil, success)
            if success { XCTAssertNil(error); XCTAssertEqual(value?.data["IN"]?.country, "India") }
            else if let transportError { XCTAssertEqual((error as? URLError)?.code, transportError) }
            else { XCTAssertTrue(error is DecodingError) }
            countries.fulfill()
        }
        api.fetchIPDetails { value, error in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertEqual(value != nil, success)
            if success { XCTAssertNil(error); XCTAssertEqual(value?.country, "India") }
            else if let transportError { XCTAssertEqual((error as? URLError)?.code, transportError) }
            else { XCTAssertTrue(error is DecodingError) }
            ip.fulfill()
        }
        api.fetchBooks(title: fixture.title, offset: 20) { result in
            XCTAssertFalse(Thread.isMainThread)
            switch result {
            case .success(let values): XCTAssertTrue(success); XCTAssertEqual(values.first?.ratingsAverage, 4.5)
            case .failure(let error):
                XCTAssertFalse(success)
                if let transportError { XCTAssertEqual((error as? URLError)?.code, transportError) }
                else { XCTAssertTrue(error is DecodingError) }
            }
            books.fulfill()
        }
        await fulfillment(of: [countries, ip, books], timeout: 5)
        XCTAssertEqual(api.fetchBooksCalledCount, 1)
    }
    func testAdditionalAndFutureRegionsRoundTrip() throws {
        for name in ["Europe", "North America", "South America", "Oceania", "New server region"] {
            let bytes = try JSONEncoder().encode(["country": "Example", "region": name])
            let datum = try JSONDecoder().decode(Datum.self, from: bytes)
            XCTAssertEqual(datum.region.rawValue, name)
            let restored = try JSONDecoder().decode(Datum.self, from: JSONEncoder().encode(datum))
            XCTAssertEqual(restored.region, datum.region)
        }
    }
    func testPunctuationRemainsInsideTitleQueryValue() async { await check(PunctuationProtocol.self, success: true) }
    func testSuccessHeadersQueryPaginationAndDTOs() async { await check(FixtureProtocol.self, success: true) }
    func testNon2xxValidJSONStillSucceeds() async { await check(Non2xxProtocol.self, success: true) }
    func testMalformedJSONPreservesDecodingErrors() async { await check(MalformedProtocol.self, success: false) }
    func testEmpty204PreservesDecodingErrors() async { await check(EmptyProtocol.self, success: false) }
    func testCancellationPreservesTransportError() async { await check(CancelledProtocol.self, success: false, transportError: .cancelled) }
    func testOfflinePreservesTransportError() async { await check(OfflineProtocol.self, success: false, transportError: .notConnectedToInternet) }
}
