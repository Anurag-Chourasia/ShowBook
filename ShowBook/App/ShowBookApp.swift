//
//  ShowBookApp.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import DesignTokensKit
import UIComponentsKit
import AuthKit
import AuthKitUI
import LocalizationKit

extension LocalizationController: @retroactive AuthLocalizing {}

private struct PersistenceControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue: PersistenceController = AppDI.shared.persistenceController
}

private struct UserViewModelEnvironmentKey: EnvironmentKey {
    static let defaultValue: UserViewModel? = nil
}

extension EnvironmentValues {
    var persistenceController: PersistenceController {
        get { self[PersistenceControllerEnvironmentKey.self] }
        set { self[PersistenceControllerEnvironmentKey.self] = newValue }
    }

    var userViewModel: UserViewModel? {
        get { self[UserViewModelEnvironmentKey.self] }
        set { self[UserViewModelEnvironmentKey.self] = newValue }
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
                    AppAuthGate(
                        brand: .showBook,
                        backendFactory: appDI.authBackendFactory,
                        localizer: localization,
                        onSignedOut: { userViewModel.clearCloudAccount() }
                    ) { user, session in
                        CloudBookRoot(user: user, session: session, userViewModel: userViewModel)
                    }
                } else {
                    LocalBookRoot(userViewModel: userViewModel)
                }
            }
            .appAppearance()
            .environment(\.designTokens, DesignTokensTheme(brand: .showBook))
            .environment(\.appDI, appDI)
            .imageDataLoader(appDI.imageDataLoader)
            .environmentObject(userViewModel)
            .environment(\.userViewModel, userViewModel)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environment(\.persistenceController, persistenceController)
            .environment(\.layoutDirection, localization.isRightToLeft ? .rightToLeft : .leftToRight)
        }
    }
}
