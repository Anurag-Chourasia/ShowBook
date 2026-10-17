import SwiftUI

struct AppLaunchView: View {
    #if DEBUG
    @State private var showingSettings = true
    @State private var configurationID = UUID()
    #endif
    var body: some View {
        #if DEBUG
        Group {
            if showingSettings {
                NavigationStack {
                    DeveloperSettingsView {
                        configurationID = UUID()
                        showingSettings = false
                    }
                }
            } else { ContentView().id(configurationID) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .developerSettingsApplied)) { _ in
            configurationID = UUID()
        }
        #else
        ContentView()
        #endif
    }
}

#if DEBUG
extension Notification.Name {
    static let developerSettingsApplied = Notification.Name("ShowBook.developerSettingsApplied")
}

struct DeveloperSettingsView: View {
    var onContinue: () -> Void
    @AppStorage("developer.discover") private var discover = true
    @AppStorage("developer.coverPreview") private var preview = true
    @AppStorage("developer.ratings") private var ratings = true
    @AppStorage("developer.httpLogs") private var logs = ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1"
    @AppStorage("developer.source") private var source = "live"
    @AppStorage("developer.scenario") private var scenario = "success"
    @AppStorage("developer.discoverVariant") private var variant = "A"
    @AppStorage("developer.version") private var version = ""
    @AppStorage("developer.build") private var build = ""

    var body: some View {
        Form {
            Section {
                Text("Developer settings are available only in Debug builds. Apply your configuration before opening the app.")
                Button("Open ShowBook", action: onContinue)
                    .accessibilityIdentifier("developer-open-app")
            }
            Section("Feature flags") {
                Toggle("Discover", isOn: $discover)
                Toggle("Cover preview", isOn: $preview)
                Toggle("Ratings", isOn: $ratings)
            }
            Section {
                Toggle("HTTP logs in Xcode console", isOn: $logs)
                Text("Full redacted request and response bodies. Large logs can slow debugging. Release builds never enable this.")
            } header: { Text("Debug logs") }
            Section {
                Picker("Data source", selection: $source) {
                    Text("Live · Open Library").tag("live")
                    Text("Stub · local fixtures").tag("stub")
                }
                if source == "stub" {
                    Picker("Stub scenario", selection: $scenario) {
                        Text("Success").tag("success")
                        Text("Empty results").tag("empty")
                        Text("Offline error").tag("offline")
                    }
                }
                Text("Live uses the production APIs. Stub replaces API responses and disables remote cover loading. Local accounts and bookmarks remain on this device.")
            } header: { Text("Environment") }
            Section {
                Picker("Discover layout", selection: $variant) {
                    Text("A · List").tag("A")
                    Text("B · Grid").tag("B")
                }
                Text("Local experiment override for visual testing. No remote assignment, analytics, or experiment results are collected.")
            } header: { Text("A/B testing") }
            Section {
                LabeledContent("Installed version", value: AppRuntime.actualVersion)
                LabeledContent("Installed build", value: AppRuntime.actualBuild)
                TextField("Simulated version (optional)", text: $version)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("Simulated build (optional)", text: $build)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Text("Overrides the version shown in Know Your Developer. The signed bundle and App Store version stay unchanged; change those in Xcode.")
            } header: { Text("Version simulation") }
            Section("Appearance") { AppearanceMenu() }
            Section {
                Button("Reset developer settings") {
                    discover = true; preview = true; ratings = true; logs = false
                    source = "live"; scenario = "success"; variant = "A"
                    version = ""; build = ""
                }
            }
        }
        .navigationTitle("Developer settings")
        .navigationBarTitleDisplayMode(.inline)
        .showBookTools(includeSettings: false)
    }
}
#endif
