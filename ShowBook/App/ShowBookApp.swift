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

extension LocalizationController: @retroactive AuthLocalizing {}

private struct PersistenceControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue: PersistenceController = AppDI.shared.persistenceController
}

extension EnvironmentValues {
    var persistenceController: PersistenceController {
        get { self[PersistenceControllerEnvironmentKey.self] }
        set { self[PersistenceControllerEnvironmentKey.self] = newValue }
    }
}

@main
struct ShowBookApp: App {
    private let appDI: AppDI
    @ObservedObject private var persistenceController: PersistenceController
    @StateObject private var userViewModel: UserViewModel
    private let localization = LocalizationController(initialLocale: .current)

    init() {
        self.init(appDI: .shared)
    }

    init(appDI: AppDI) {
        self.appDI = appDI
        self.persistenceController = appDI.persistenceController
        _userViewModel = StateObject(wrappedValue: appDI.makeUserViewModel())
    }

    init(persistenceController: PersistenceController) {
        let appDI = AppDI(persistenceController: persistenceController)
        self.appDI = appDI
        self.persistenceController = persistenceController
        _userViewModel = StateObject(wrappedValue: appDI.makeUserViewModel())
    }

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
                .environment(\.designTokens, DesignTokensTheme(brand: .showBook))
                .environment(\.appDI, appDI)
                .environmentObject(userViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.persistenceController, persistenceController)
                .environment(\.layoutDirection, localization.isRightToLeft ? .rightToLeft : .leftToRight)
        }
    }
}

/// Bind bookmark identity before mounting any data-reading dashboard views.
private struct CloudBookRoot: View {
    let user: AuthUser
    let session: SessionManager
    @ObservedObject var userViewModel: UserViewModel
    private let localization = LocalizationController(initialLocale: .current)
    @State private var activatedIdentity: String?
    private var identity: String { "\(user.id)|\(user.email ?? "")" }
    var body: some View {
        Group {
            if activatedIdentity == identity && userViewModel.isLoggedIn && userViewModel.currentUserUUID == user.id {
                ContentView()
            } else if let error = userViewModel.activationError {
                VStack {
                    StoreLoadErrorRecoveryView(error: error, localization: localization) {
                        userViewModel.retryCloudActivation()
                        if userViewModel.isLoggedIn { activatedIdentity = identity }
                    }
                    Button(L10n.Auth.signOut(using: localization)) {
                        userViewModel.abandonCloudActivation()
                    }
                }
            } else {
                ProgressView(String(\ShowBookStrings.loadingLibrary))
            }
        }
        .task(id: identity) {
            activatedIdentity = nil
            userViewModel.activateCloudAccount(user: user) {
                Task { await session.signOut() }
            }
            if userViewModel.isLoggedIn { activatedIdentity = identity }
        }
    }
}

/// Clear transient cloud identity before mounting the legacy account screens.
private struct LocalBookRoot: View {
    @ObservedObject var userViewModel: UserViewModel
    @State private var ready = false
    var body: some View {
        Group {
            if ready { ContentView() } else { ProgressView(String(\ShowBookStrings.loadingLibrary)) }
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
    var localization: LocalizationProviding = LocalizationController(initialLocale: .current)
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: \.sixteen) {
            Image(\.exclamationmarkTriangleFill)
                .foregroundColor(\.yellow)
            Text(L10n.Errors.storeLoadFailed(using: localization))
                .font(\.headline)
                .foregroundColor(\.primary)
            Text(L10n.Errors.storeLoadMessage(using: localization))
                .font(\.subheadline)
                .foregroundColor(\.secondary)
                .multilineTextAlignment(.center)
            Button(L10n.Errors.recoverableRetry(using: localization)) {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
            .tint(\.primary)
        }
        .padding(.horizontal, \.p34)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(\.grouped)
        .environment(\.layoutDirection, localization.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}
