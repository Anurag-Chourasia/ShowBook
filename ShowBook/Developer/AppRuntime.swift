import Foundation
import Combine
import CommonNetworkingKit

/// Release behaviour is independent of any developer preferences left on a device.
enum AppRuntime {
    /// Debug opt-in; production rollout never reads developer preferences.
    static var authenticationEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "developer.authentication")
        #else
        return Bundle.main.object(forInfoDictionaryKey: "AUTHKIT_ENABLED") as? Bool ?? false
        #endif
    }

    static let actualVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    static let actualBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    static var discoverEnabled: Bool { flag("discover") }
    static var coverPreviewEnabled: Bool { flag("coverPreview") }
    static var ratingsEnabled: Bool { flag("ratings") }
    static var version: String { override("version", fallback: actualVersion) }
    static var build: String { override("build", fallback: actualBuild) }

    #if DEBUG
    /// Indicates whether the app was launched with the Showcase CLI argument or environment.
    static var isShowcaseLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("-Showcase") ||
        ProcessInfo.processInfo.arguments.contains("-ShowcaseMode") ||
        ProcessInfo.processInfo.environment["SHOWCASE_MODE"] == "1"
    }

    /// True when running in the curated credential-free Showcase experience.
    static var isShowcaseMode: Bool {
        if let scenario = stubScenario {
            return scenario == "showcase" || isShowcaseLaunch
        }
        return isShowcaseLaunch
    }
    #else
    static var isShowcaseLaunch: Bool { false }
    static var isShowcaseMode: Bool { false }
    #endif

    static var stubScenario: String? {
        #if DEBUG
        let source = UserDefaults.standard.string(forKey: "developer.source")
        if source == "live" { return nil }
        if source == "stub" {
            let value = UserDefaults.standard.string(forKey: "developer.scenario") ?? "success"
            return ["success", "showcase", "empty", "offline"].contains(value) ? value : "success"
        }
        if isShowcaseLaunch { return "showcase" }
        return nil
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
    static func client(session: URLSession? = nil) -> CommonNetworkingKit.HTTPClient {
        context(session: session).client
    }

    static func dataTaskPublisher(for url: URL, session: URLSession? = nil) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        let transport = client(session: session)
        return Future<(data: Data, response: URLResponse), Error> { promise in
            Task {
                do {
                    let res = try await transport.send(URLRequest(url: url))
                    promise(.success((data: res.data, response: res.response)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Capture the source once so a settings change during a request cannot mix cache environments.
    static func context(session: URLSession? = nil) -> (client: CommonNetworkingKit.HTTPClient, namespace: String) {
        #if DEBUG
        let scenario = AppRuntime.stubScenario
        let namespace = scenario.map { "stub-" + $0 } ?? "live"
        let enabled = UserDefaults.standard.object(forKey: "developer.httpLogs") as? Bool
            ?? (ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1")
        let logger: HTTPLogger? = enabled ? .console : nil
        if let session { return (CommonNetworkingKit.HTTPClient(session: session, logger: logger), namespace) }
        if let scenario {
            let session: URLSession
            switch scenario {
            case "offline": session = DeveloperStubSessions.offline
            case "empty": session = DeveloperStubSessions.empty
            case "showcase": session = DeveloperStubSessions.showcase
            default: session = DeveloperStubSessions.success
            }
            return (CommonNetworkingKit.HTTPClient(session: session, logger: logger), namespace)
        }
        return (CommonNetworkingKit.HTTPClient(session: .shared, logger: logger), namespace)
        #else
        return (CommonNetworkingKit.HTTPClient(session: session ?? .shared), "live")
        #endif
    }
}

#if DEBUG
private enum DeveloperStubSessions {
    static let success = make(DeveloperStubProtocol.self)
    static let showcase = make(ShowcaseStubProtocol.self)
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
        let route: String
        var payloadScenario = scenario
        if url.host == "openlibrary.org" {
            if url.path.hasPrefix("/subjects/") { route = "subjects" } else if url.path == "/search.json" {
                route = "search"
                let offset = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first { $0.name == "offset" }?.value ?? "0"
                if scenario != "showcase", offset != "0" { payloadScenario = "empty" }
            } else if url.path.hasSuffix("/editions.json") { route = "editions" } else if url.path.hasPrefix("/works/") { route = "work" } else if url.path.hasPrefix("/books/") { route = "edition" } else { return nil }
        } else if url.host == "api.first.org" { route = "countries" } else { return nil }
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        let directory: String? = nil
        #else
        let bundle = Bundle.main
        let directory: String? = "DeveloperFixtures"
        #endif
        guard let file = bundle.url(forResource: "showbook-developer-responses", withExtension: "json", subdirectory: directory),
              let data = try? Data(contentsOf: file),
              let catalog = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]],
              let payload = catalog[payloadScenario]?[route],
              let body = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else { return nil }
        return String(data: body, encoding: .utf8)
    }
}
final class EmptyStubProtocol: DeveloperStubProtocol { override class var scenario: String { "empty" } }
final class OfflineStubProtocol: DeveloperStubProtocol { override class var scenario: String { "offline" } }
final class ShowcaseStubProtocol: DeveloperStubProtocol { override class var scenario: String { "showcase" } }

#endif
