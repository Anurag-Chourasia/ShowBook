import SwiftUI
import DesignTokensKit
import LocalizationKit

struct AppLaunchView<Content: View>: View {
    let content: (Bool) -> Content
    @State private var authenticationEnabled = AppRuntime.authenticationEnabled

    init(@ViewBuilder content: @escaping (Bool) -> Content) { self.content = content }

    #if DEBUG
    @State private var showingLaunchSettings = !AppRuntime.isShowcaseLaunch
    @State private var showingSettingsSheet = false
    @State private var configurationID = UUID()
    #endif

    var body: some View {
        #if DEBUG
        Group {
            if showingLaunchSettings {
                NavigationStack {
                    DeveloperSettingsView(buttonTitle: "Open ShowBook") {
                        authenticationEnabled = AppRuntime.authenticationEnabled
                        showingLaunchSettings = false
                    }
                }
            } else {
                content(authenticationEnabled)
                    .id(configurationID)
                    .safeAreaInset(edge: .top) {
                        if AppRuntime.isShowcaseMode {
                            ShowcaseBadgeView {
                                showingSettingsSheet = true
                            }
                        }
                    }
                    .sheet(isPresented: $showingSettingsSheet) {
                        NavigationStack {
                            DeveloperSettingsView(buttonTitle: "Close") {
                                showingSettingsSheet = false
                                authenticationEnabled = AppRuntime.authenticationEnabled
                                configurationID = UUID()
                            }
                        }
                    }
            }
        }
        .background(DebugSettingsPresenter(isLaunchSettingsVisible: showingLaunchSettings) {
            authenticationEnabled = AppRuntime.authenticationEnabled
            configurationID = UUID()
        })
        #else
        content(authenticationEnabled)
        #endif
    }
}

#if DEBUG
struct ShowcaseBadgeView: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: \.four) {
                Image(\.sparkles)
                    .font(\.caption2)
                Text(\.showcaseDemoTitle)
                    .font(\.caption)
                    .fontWeight(.bold)
                Text(\.showcaseDemoTapForControls)
                    .font(\.caption2)
                    .opacity(\.p0_5)
            }
            .padding(.horizontal, \.ten)
            .padding(.vertical, \.four)
            .background(.ultraThinMaterial)
            .foregroundColor(ShowBookTheme.colors.action)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(ShowBookTheme.colors.action.opacity(OpacityTheme.default.p0_35), lineWidth: DesignMetricTheme.default.p1)
            )
        }
        .padding(.top, \.four)
        .accessibilityIdentifier("showcase-demo-indicator")
        .accessibilityLabel(\.showcaseDemoA11y)
    }
}
#endif

#if DEBUG
private extension Notification.Name {
    static let deviceShaken = Notification.Name("ShowBook.deviceShaken")
}

// The window remains in the responder chain across navigation, keyboards,
// and presented sheets. Do not take first responder away from text fields.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceShaken, object: self)
    }
}

private struct DebugSettingsPresenter: UIViewControllerRepresentable {
    var isLaunchSettingsVisible: Bool
    var onApply: () -> Void

    func makeUIViewController(context: Context) -> Presenter {
        Presenter()
    }

    func updateUIViewController(_ controller: Presenter, context: Context) {
        controller.isLaunchSettingsVisible = isLaunchSettingsVisible
        controller.onApply = onApply
    }

    final class Presenter: UIViewController, UIAdaptivePresentationControllerDelegate {
        var isLaunchSettingsVisible = false
        var onApply: () -> Void = {}
        private weak var settingsController: UIViewController?

        override func viewDidLoad() {
            super.viewDidLoad()
            NotificationCenter.default.addObserver(self, selector: #selector(showSettings(_:)),
                                                   name: .deviceShaken, object: nil)
        }

        deinit { NotificationCenter.default.removeObserver(self) }

        @objc private func showSettings(_ notification: Notification) {
            guard let window = notification.object as? UIWindow,
                  window === view.window,
                  !isLaunchSettingsVisible, settingsController == nil,
                  var presenter = window.rootViewController else { return }
            // Present above the currently open sheet, preserving its navigation state.
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            guard !presenter.isBeingDismissed, !presenter.isBeingPresented else { return }
            let settings = UIHostingController(rootView: NavigationStack {
                DeveloperSettingsView { [weak self] in
                    self?.settingsController?.dismiss(animated: true) {
                        self?.settingsController = nil
                        self?.onApply()
                    }
                }
            }.appAppearance())
            settingsController = settings
            presenter.present(settings, animated: true)
            settings.presentationController?.delegate = self
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            settingsController = nil
            onApply()
        }
    }
}

struct DeveloperSettingsView: View {
    var buttonTitle = "Apply and close"
    var onContinue: () -> Void
    @AppStorage("developer.authentication") private var authentication = false
    @AppStorage("developer.discover") private var discover = true
    @AppStorage("developer.coverPreview") private var preview = true
    @AppStorage("developer.ratings") private var ratings = true
    @AppStorage("developer.httpLogs") private var logs = ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1"
    @AppStorage("developer.source") private var source = "live"
    @AppStorage("developer.scenario") private var scenario = "success"
    @AppStorage("developer.discoverVariant") private var variant = "A"
    @AppStorage("developer.version") private var version = ""
    @AppStorage("developer.build") private var build = ""
    @State private var cacheSummary = ""

    private let diskCache = BookCatalogCache.shared

    var body: some View {
        Form {
            Section {
                Text("Configure ShowBook runtime, cache, and feature flags. Shake device from any screen to reopen.")
                Button(buttonTitle, action: onContinue)
                    .foregroundColor(\.primary)
                    .accessibilityIdentifier("developer-open-app")
            }
            Section("Quick presets") {
                Button {
                    source = "stub"
                    scenario = "showcase"
                    onContinue()
                } label: {
                    Label("Showcase (Populated)", systemImage: "sparkles")
                }
                .accessibilityIdentifier("developer-preset-showcase")

                Button {
                    source = "stub"
                    scenario = "empty"
                    onContinue()
                } label: {
                    Label("Empty State (Zero Results)", systemImage: "tray")
                }
                .accessibilityIdentifier("developer-preset-empty")

                Button {
                    source = "stub"
                    scenario = "offline"
                    onContinue()
                } label: {
                    Label("Offline Resilience", systemImage: "wifi.slash")
                }
                .accessibilityIdentifier("developer-preset-offline")

                Button {
                    source = "live"
                    onContinue()
                } label: {
                    Label("Live Open Library", systemImage: "globe")
                }
                .accessibilityIdentifier("developer-preset-live")
            }
            Section("Cache & offline storage") {
                LabeledContent("Disk cache", value: cacheSummary.isEmpty ? "Checking..." : cacheSummary)
                Button("Purge catalog cache", role: .destructive) {
                    diskCache.clear()
                    refreshCacheSummary()
                }
                .accessibilityIdentifier("developer-purge-cache")
            }
            Section("Feature flags") {
                Toggle("Authentication · AuthKit", isOn: $authentication)
                    .accessibilityIdentifier("developer-authentication")
                Text("New feature, off by default. Enable to use cloud sign-in. Apply settings to activate changes; disabling it preserves the saved cloud session.")

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
            Section("Privacy & Support") {
                Link(destination: URL(string: "https://github.com/Anurag-Chourasia/ShowBook/blob/main/Docs/PrivacyInventory.md")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                .accessibilityIdentifier("developer-privacy-policy")

                Link(destination: URL(string: "mailto:anuragchourasiaios@gmail.com")!) {
                    Label("Developer Support", systemImage: "envelope")
                }
                .accessibilityIdentifier("developer-support")

                Text("ShowBook stores user bookmarks locally on device or securely in Supabase when cloud authentication is enabled. No personal data is tracked or sold to third parties.")
                    .font(\.caption)
                    .foregroundColor(\.secondary)
            }
            Section {
                Button("Reset developer settings") {
                    authentication = false; discover = true; preview = true; ratings = true; logs = false
                    source = "live"; scenario = "success"; variant = "A"
                    version = ""; build = ""
                }
                .foregroundColor(\.primary)
            }
        }
        .navigationTitle("Developer settings")
        .navigationBarTitleDisplayMode(.inline)
        .tint(\.primary)
        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.default.green))
        .onAppear {
            refreshCacheSummary()
        }
    }

    private func refreshCacheSummary() {
        let count = diskCache.cachedQueriesCount
        if count == 0 {
            cacheSummary = "0 queries (0 KB)"
        } else {
            cacheSummary = "\(count) queries (\(diskCache.formattedFileSize))"
        }
    }
}
#endif
