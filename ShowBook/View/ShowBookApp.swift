//
//  ShowBookApp.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import AuthKit
import AuthKitUI

@main
struct ShowBookApp: App {
    private let persistenceController = PersistenceController.shared
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            AppLaunchView { authenticationEnabled in
                if authenticationEnabled {
                    AppAuthGate(brand: .showBook, onSignedOut: { userViewModel.clearCloudAccount() }) { user, session in
                        CloudBookRoot(user: user, session: session, userViewModel: userViewModel)
                    }
                } else {
                    LocalBookRoot(userViewModel: userViewModel)
                }
            }
                .appAppearance()
                .environmentObject(userViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
            if ready { ContentView() }
            else { ProgressView("Opening library") }
        }
        .task {
            // Preserve existing per-email bookmarks. Providers without an email get a
            // stable UUID namespace, never the previous user's saved-book scope.
            userViewModel.activateCloudAccount(email: user.email ?? "supabase:\(user.id.uuidString)") {
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
            if ready { ContentView() }
            else { ProgressView("Opening library") }
        }
        .task {
            if userViewModel.cloudSignOut != nil { userViewModel.clearCloudAccount() }
            userViewModel.checkLoginStatus()
            ready = true
        }
    }
}
