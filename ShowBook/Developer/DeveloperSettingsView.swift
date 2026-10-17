import SwiftUI
import DesignTokensKit

struct AppLaunchView: View {
    #if DEBUG
    @State private var showingLaunchSettings = true
    @State private var configurationID = UUID()
    #endif

    var body: some View {
        #if DEBUG
        Group {
            if showingLaunchSettings {
                NavigationStack {
                    DeveloperSettingsView(buttonTitle: "Open ShowBook") {
                        showingLaunchSettings = false
                    }
                }
            } else {
                ContentView().id(configurationID)
            }
        }
        .background(DebugSettingsPresenter(isLaunchSettingsVisible: showingLaunchSettings) {
            configurationID = UUID()
        })
        #else
        ContentView()
        #endif
    }
}

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
                Text("Configure ShowBook, then continue. Shake the device from any screen to return to these settings.")
                Button(buttonTitle, action: onContinue)
                    .foregroundStyle(DesignColor.primary)
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
                .foregroundStyle(DesignColor.primary)
            }
        }
        .navigationTitle("Developer settings")
        .navigationBarTitleDisplayMode(.inline)
        .tint(DesignColor.primary)
        .toggleStyle(SwitchToggleStyle(tint: DesignColor.green))
    }
}
#endif
