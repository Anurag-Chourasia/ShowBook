import Foundation
import CommonNetworking

/// Release behaviour is independent of any developer preferences left on a device.
enum AppRuntime {
    static let actualVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    static let actualBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    static var discoverEnabled: Bool { flag("discover") }
    static var coverPreviewEnabled: Bool { flag("coverPreview") }
    static var ratingsEnabled: Bool { flag("ratings") }
    static var version: String { override("version", fallback: actualVersion) }
    static var build: String { override("build", fallback: actualBuild) }
    static var stubScenario: String? {
        #if DEBUG
        guard UserDefaults.standard.string(forKey: "developer.source") == "stub" else { return nil }
        let value = UserDefaults.standard.string(forKey: "developer.scenario") ?? "success"
        return ["success", "empty", "offline"].contains(value) ? value : "success"
        #else
        return nil
        #endif
    }
    static var cacheNamespace: String { stubScenario.map { "stub-" + $0 } ?? "live" }
    static var discoverGrid: Bool {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "developer.discoverVariant") == "B"
        #else
        return false
        #endif
    }
    private static func flag(_ name: String) -> Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: "developer." + name) as? Bool ?? true
        #else
        return true
        #endif
    }
    private static func override(_ key: String, fallback: String) -> String {
        #if DEBUG
        let value = UserDefaults.standard.string(forKey: "developer." + key)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? fallback : value
        #else
        return fallback
        #endif
    }
}

enum AppNetworking {
    static func client(session: URLSession? = nil) -> CommonNetworking.HTTPClient {
        context(session: session).client
    }
    /// Capture the source once so a settings change during a request cannot mix cache environments.
    static func context(session: URLSession? = nil) -> (client: CommonNetworking.HTTPClient, namespace: String) {
        #if DEBUG
        let scenario = AppRuntime.stubScenario
        let namespace = scenario.map { "stub-" + $0 } ?? "live"
        let enabled = UserDefaults.standard.object(forKey: "developer.httpLogs") as? Bool
            ?? (ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1")
        let logger: HTTPLogger? = enabled ? .console : nil
        if let session { return (CommonNetworking.HTTPClient(session: session, logger: logger), namespace) }
        if let scenario {
            let session: URLSession
            switch scenario {
            case "offline": session = DeveloperStubSessions.offline
            case "empty": session = DeveloperStubSessions.empty
            default: session = DeveloperStubSessions.success
            }
            return (CommonNetworking.HTTPClient(session: session, logger: logger), namespace)
        }
        return (CommonNetworking.HTTPClient(session: .shared, logger: logger), namespace)
        #else
        return (CommonNetworking.HTTPClient(session: session ?? .shared), "live")
        #endif
    }
}

#if DEBUG
private enum DeveloperStubSessions {
    static let success = make(DeveloperStubProtocol.self)
    static let empty = make(EmptyStubProtocol.self)
    static let offline = make(OfflineStubProtocol.self)
    private static func make(_ protocolClass: AnyClass) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [protocolClass]
        return URLSession(configuration: configuration)
    }
}

/// Installed only on explicitly selected ephemeral sessions, never globally.
class DeveloperStubProtocol: URLProtocol {
    class var scenario: String { "success" }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() {
        guard Self.scenario != "offline" else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)); return
        }
        guard let url = request.url, let body = Self.body(for: url) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL)); return
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    class func body(for url: URL) -> String? {
        let empty = scenario == "empty"
        if url.host == "openlibrary.org" {
            if url.path.hasPrefix("/subjects/") {
                return empty ? #"{"works":[]}"# : #"{"works":[{"key":"/works/OL45804W","title":"Demo: A journey through books","authors":[{"name":"Fixture Author"}]},{"key":"/works/OL45805W","title":"Demo: The second chapter","authors":[]}]}"#
            }
            if url.path == "/search.json" {
                let offset = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "offset" }?.value ?? "0"
                return empty || offset != "0" ? #"{"docs":[]}"# : #"{"docs":[{"key":"/works/OL45804W","title":"Demo: A journey through books","author_name":["Fixture Author"],"ratings_average":4.2,"ratings_count":10}]}"#
            }
            if url.path.hasSuffix("/editions.json") { return #"{"size":0,"entries":[]}"# }
            if url.path.hasPrefix("/works/") {
                return #"{"key":"/works/OL45804W","title":"Demo: A journey through books","description":"This is local stub data for testing. No book API request was sent.","subjects":["Demo"]}"#
            }
            if url.path.hasPrefix("/books/") { return #"{"key":"/books/OL1M","title":"Demo edition"}"# }
        }
        if url.host == "api.first.org" {
            return #"{"status":"OK","status-code":200,"version":"1.0","access":"public","total":1,"offset":0,"limit":1,"data":{"IN":{"country":"India","region":"Asia"}}}"#
        }
        if url.host == "ip-api.com" {
            return #"{"status":"success","country":"India","countryCode":"IN","region":"TG","regionName":"Telangana","city":"Demo city","zip":"","lat":0,"lon":0,"timezone":"Asia/Kolkata","isp":"Stub","org":"Stub","as":"Stub","query":"127.0.0.1"}"#
        }
        return nil
    }
}
final class EmptyStubProtocol: DeveloperStubProtocol { override class var scenario: String { "empty" } }
final class OfflineStubProtocol: DeveloperStubProtocol { override class var scenario: String { "offline" } }
#endif
