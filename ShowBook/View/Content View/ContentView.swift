//
//  ContentView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

struct ContentView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    var body: some View {
            if userViewModel.isLoggedIn {
                DashboardView()
                    .tag(1)
                    .environmentObject(userViewModel)
            } else {
                LandingView()
                    .tag(2)
                    .environmentObject(userViewModel)
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UserViewModel())
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
}

struct AppearanceMenu: View {
    var iconOnly = false
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system

    var body: some View {
        Group {
            if iconOnly {
                Menu {
                    appearancePicker.pickerStyle(.inline)
                } label: {
                    Image(\.circleLefthalfFilled)
                }
                .accessibilityLabel(\.appearance)
                .accessibilityIdentifier(.appearanceMenu)
            } else {
                appearancePicker.pickerStyle(.menu)
            }
        }
        .tint(\.primary)
        .foregroundColor(\.primary)
    }

    private var appearancePicker: some View {
        Picker(selection: $appearance) {
            Text("System").tag(AppAppearance.system)
            Text("Light").tag(AppAppearance.light)
            Text("Dark").tag(AppAppearance.dark)
        } label: { Label(Text(\.appearance), \.circleLefthalfFilled) }
    }
}

/// Apply to this scene's window so navigation destinations and sheets inherit it.
/// `.unspecified` restores the current system style, including after an override.
private struct WindowAppearance: UIViewRepresentable {
    let style: UIUserInterfaceStyle
    func makeUIView(context: Context) -> AppearanceView { AppearanceView() }
    func updateUIView(_ view: AppearanceView, context: Context) { view.style = style }

    final class AppearanceView: UIView {
        var style: UIUserInterfaceStyle = .unspecified { didSet { apply() } }
        override func didMoveToWindow() { super.didMoveToWindow(); apply() }
        private func apply() {
            guard let window, window.overrideUserInterfaceStyle != style else { return }
            window.overrideUserInterfaceStyle = style
        }
    }
}

private struct AppAppearanceModifier: ViewModifier {
    @AppStorage("appAppearance") private var selection: AppAppearance = .system
    func body(content: Content) -> some View {
        content.background(WindowAppearance(style: selection.interfaceStyle).allowsHitTesting(false))
    }
}

extension AppAppearance {
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension View {
    func appAppearance() -> some View { modifier(AppAppearanceModifier()) }
}

private struct ShowBookTools: ViewModifier {
    var includeDeveloper: Bool
    var includeLayout: Bool
    var onLogout: (() -> Void)?
    @State private var savedPresented = false
    @State private var developerPresented = false
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if onLogout != nil {
                            Button { savedPresented = true } label: {
                                Label(Text(\.savedBooks), \.bookmark)
                            }
                            .accessibilityIdentifier(.bookmarkButton)
                        }
                        AppearanceMenu()
                        if includeLayout { BookLayoutPicker() }
                        if includeDeveloper {
                            Button { developerPresented = true } label: {
                                Label(Text(\.knowYourDeveloper), \.personCropCircle)
                            }
                        }
                        if let onLogout {
                            Section {
                                Button(role: .destructive, action: onLogout) {
                                    Label(Text(\.logout), \.rectanglePortraitAndArrowRight)
                                }
                            }
                        }
                    } label: { Label(Text(\.appOptions), \.line3Horizontal) }
                    .tint(\.primary)
                    .accessibilityIdentifier(.screenTools)
                }
            }
            .navigationDestination(isPresented: $savedPresented) { BookmarkView() }
            .sheet(isPresented: $developerPresented) {
                NavigationStack {
                    ShowBookDeveloperView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button { developerPresented = false } label: { Image(\.close) }
                                    .accessibilityLabel(\.developerCloseProfile)
                            }
                        }
                }
            }
    }
}

extension View {
    func showBookTools(includeDeveloper: Bool = true, includeLayout: Bool = false,
                       onLogout: (() -> Void)? = nil) -> some View {
        modifier(ShowBookTools(includeDeveloper: includeDeveloper, includeLayout: includeLayout, onLogout: onLogout))
    }
}
