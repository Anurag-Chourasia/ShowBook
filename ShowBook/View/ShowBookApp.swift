//
//  ShowBookApp.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import DesignTokensKit
import AuthKit
import AuthKitUI
import LocalizationKit

extension LocalizationController: AuthLocalizing {}

@main
struct ShowBookApp: App {
    @ObservedObject private var persistenceController = PersistenceController.shared
    @StateObject private var userViewModel = UserViewModel()
    private let localization = LocalizationController()
    
    var body: some Scene {
        WindowGroup {
            AppLaunchView { authenticationEnabled in
                if let error = persistenceController.storeLoadError {
                    StoreLoadErrorRecoveryView(error: error, localization: localization) {
                        persistenceController.retryLoadingStore()
                    }
                } else if authenticationEnabled {
                    AppAuthGate(brand: .showBook, localizer: localization, onSignedOut: { userViewModel.clearCloudAccount() }) { user, session in
                        CloudBookRoot(user: user, session: session, userViewModel: userViewModel)
                    }
                } else {
                    LocalBookRoot(userViewModel: userViewModel)
                }
            }
                .appAppearance()
                .environmentObject(userViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.layoutDirection, localization.isRightToLeft ? .rightToLeft : .leftToRight)
        }
    }
}

/// Bind bookmark identity before mounting any data-reading dashboard views.
private struct CloudBookRoot: View {
    let user: AuthUser
    let session: SessionManager
    @ObservedObject var userViewModel: UserViewModel
    @State private var ready = false
    var body: some View {
        Group {
            if ready { ContentView() } else { ProgressView("Opening library") }
        }
        .task {
            // Bind stable UUID identity and migrate existing email bookmarks
            userViewModel.activateCloudAccount(user: user) {
                Task { await session.signOut() }
            }
            ready = true
        }
    }
}

/// Clear transient cloud identity before mounting the legacy account screens.
private struct LocalBookRoot: View {
    @ObservedObject var userViewModel: UserViewModel
    @State private var ready = false
    var body: some View {
        Group {
            if ready { ContentView() } else { ProgressView("Opening library") }
        }
        .task {
            if userViewModel.cloudSignOut != nil { userViewModel.clearCloudAccount() }
            userViewModel.checkLoginStatus()
            ready = true
        }
    }
}

/// Present recoverable store-load failures without automatic data deletion.
struct StoreLoadErrorRecoveryView: View {
    let error: Error
    var localization: LocalizationProviding = LocalizationController()
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: DesignMetric.p16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignColor.yellow)
            Text(L10n.Errors.storeLoadFailed(using: localization))
                .font(Typography.headline)
                .foregroundStyle(DesignColor.primary)
            Text(L10n.Errors.storeLoadMessage(using: localization))
                .font(Typography.subheadline)
                .foregroundStyle(DesignColor.secondary)
                .multilineTextAlignment(.center)
            Button(L10n.Errors.recoverableRetry(using: localization)) {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignColor.primary)
        }
        .padding(.horizontal, DesignMetric.p34)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignColor.grouped)
        .environment(\.layoutDirection, localization.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}
