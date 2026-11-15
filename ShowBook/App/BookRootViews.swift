//
//  BookRootViews.swift
//  ShowBook
//

import SwiftUI
import AuthKit
import LocalizationKit

/// Bind bookmark identity before mounting any data-reading dashboard views.
struct CloudBookRoot: View {
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
                    Button(\.logout) {
                        userViewModel.abandonCloudActivation()
                    }
                }
            } else {
                ProgressView { Text(\.loadingLibrary) }
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
struct LocalBookRoot: View {
    @ObservedObject var userViewModel: UserViewModel
    @State private var ready = false

    var body: some View {
        Group {
            if ready { ContentView() } else { ProgressView { Text(\.loadingLibrary) } }
        }
        .task {
            if userViewModel.cloudSignOut != nil { userViewModel.clearCloudAccount() }
            userViewModel.checkLoginStatus()
            ready = true
        }
    }
}
