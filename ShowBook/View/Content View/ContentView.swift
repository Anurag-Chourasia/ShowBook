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

public typealias AppAppearance = UIComponentsKit.AppAppearance

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
                        AppearanceMenu(title: String(\ShowBookStrings.appearance), systemTitle: String(\ShowBookStrings.appearanceSystem), lightTitle: String(\ShowBookStrings.light), darkTitle: String(\ShowBookStrings.dark))
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
