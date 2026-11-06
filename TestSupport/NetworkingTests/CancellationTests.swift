import Foundation
import XCTest
@testable import Adapter

private final class DelayedMetadataProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var delayed = true
    private static var started: (() -> Void)?
    private static var stopped: (() -> Void)?
    private var onStop: (() -> Void)?

    static func configure(delayed: Bool, started: (() -> Void)? = nil, stopped: (() -> Void)? = nil) {
        lock.lock()
        defer { lock.unlock() }
        self.delayed = delayed
        self.started = started
        self.stopped = stopped
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        let delayed = Self.delayed
        let started = Self.started
        onStop = Self.stopped
        Self.lock.unlock()
        started?()
        guard !delayed else { return }
        do {
            guard let url = request.url else { throw URLError(.badURL) }
            let file = url.path == "/search.json" ? "books" : "countries"
            guard let fixture = Bundle.module.url(forResource: file, withExtension: "json"),
                  let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            else { throw CocoaError(.fileNoSuchFile) }
            let data = try Data(contentsOf: fixture)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() { onStop?() }
}

final class MetadataCancellationTests: XCTestCase {
    private func checkCancellation(countries: Bool) async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [DelayedMetadataProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let api = NetworkClass(session: session)
        let started = expectation(description: "Transport started")
        let stopped = expectation(description: "Transport canceled")
        let completed = expectation(description: "Cancellation delivered")
        DelayedMetadataProtocol.configure(delayed: true, started: { started.fulfill() }, stopped: { stopped.fulfill() })
        let task: Task<Void, Never>?
        if countries {
            task = api.fetchCountries { value, error in
                XCTAssertNil(value)
                XCTAssertEqual((error as? URLError)?.code, .cancelled)
                completed.fulfill()
            }
        } else {
            task = api.fetchBooks(title: "blocked", offset: 0) { result in
                guard case .failure(let error) = result else { return XCTFail("Canceled request succeeded") }
                XCTAssertEqual((error as? URLError)?.code, .cancelled)
                completed.fulfill()
            }
        }
        let handle = try XCTUnwrap(task)
        await fulfillment(of: [started], timeout: 2)
        handle.cancel()
        await fulfillment(of: [stopped, completed], timeout: 2)

        DelayedMetadataProtocol.configure(delayed: false)
        let subsequent = expectation(description: "Subsequent request remains usable")
        if countries {
            api.fetchCountries { value, error in
                XCTAssertNil(error)
                XCTAssertNotNil(value)
                subsequent.fulfill()
            }
        } else {
            api.fetchBooks(title: "Swift book", offset: 0) { result in
                XCTAssertEqual(try? result.get().first?.title, "Fixture Book")
                subsequent.fulfill()
            }
        }
        await fulfillment(of: [subsequent], timeout: 2)
    }
    func testBookRequestCancellationStopsTransportAndAllowsNextRequest() async throws {
        try await checkCancellation(countries: false)
    }
    func testCountryRequestCancellationStopsTransportAndAllowsNextRequest() async throws {
        try await checkCancellation(countries: true)
    }
}
