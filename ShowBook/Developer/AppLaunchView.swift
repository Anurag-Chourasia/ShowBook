//
//  AppLaunchView.swift
//  ShowBook
//

import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

struct AppLaunchView<Content: View>: View {
    let content: (Bool) -> Content
    @State private var authenticationEnabled = AppRuntime.authenticationEnabled

    init(@ViewBuilder content: @escaping (Bool) -> Content) {
        self.content = content
    }

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
                    DeveloperSettingsView(buttonTitle: String(\CommonStrings.developerOpenApp)) {
                        authenticationEnabled = AppRuntime.authenticationEnabled
                        showingLaunchSettings = false
                    }
                }
            } else {
                VStack(spacing: \.zero) {
                    if AppRuntime.isShowcaseMode {
                        ShowcaseBadgeView { showingSettingsSheet = true }
                    }
                    content(authenticationEnabled).id(configurationID)
                }
                .sheet(isPresented: $showingSettingsSheet) {
                    NavigationStack {
                        DeveloperSettingsView(buttonTitle: String(\CommonStrings.close)) {
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
