//
//  UserViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import Combine
#if canImport(AuthKit)
import AuthKit
#endif

class UserViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserUUID: UUID?
    @Published private(set) var activationError: Error?
    private var pendingActivation: (email: String, uuid: UUID, signOut: () -> Void)?
    var migrateIdentity: (PersistenceController, String, UUID) throws -> Void = { controller, email, uuid in
        try controller.activateCloudIdentity(email: email, uuid: uuid)
    }
    var cloudSignOut: (() -> Void)?
    var cloudDeleteAccount: (() -> Void)?
    var cloudUpdateProfile: ((_ email: String?, _ first: String?, _ last: String?, _ phone: String?) -> Void)?
    var cloudUpdatePassword: ((String) async throws -> Void)?
    var persistenceController: PersistenceController

    var currentUserEmail: String? {
        UserDefaults.standard.string(forKey: "LoggedInUserEmail")
    }

    #if canImport(AuthKit)
    var cloudUser: AuthUser?
    var authUser: AuthUser? {
        guard isLoggedIn, let uuid = currentUserUUID else { return nil }
        return cloudUser ?? AuthUser(id: uuid, email: currentUserEmail)
    }
    #endif

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        checkLoginStatus()
    }

    #if DEBUG
    convenience init() {
        self.init(persistenceController: PersistenceController.inMemory())
    }
    #endif

    func setUpPersistenceController(controller: PersistenceController) {
        persistenceController = controller
        checkLoginStatus()
    }

    func checkLoginStatus() {
        guard pendingActivation == nil else { isLoggedIn = false; return }
        if let uuidString = UserDefaults.standard.string(forKey: "LoggedInUserUUID"),
           let uuid = UUID(uuidString: uuidString) {
            currentUserUUID = uuid
            isLoggedIn = true
        } else {
            currentUserUUID = nil
            isLoggedIn = false
        }
    }

    #if canImport(AuthKit)
    func activateCloudAccount(
        user: AuthUser,
        session: SessionManager? = nil,
        signOut: @escaping () -> Void,
        deleteAccount: (() -> Void)? = nil
    ) {
        cloudUser = user
        if let session {
            cloudUpdateProfile = { [weak session] email, first, last, phone in
                Task { await session?.updateProfile(email: email, firstName: first, lastName: last, phone: phone) }
            }
            cloudUpdatePassword = { [weak session] password in
                try await session?.updatePassword(password)
            }
        }
        activateCloudAccount(
            email: user.email ?? "",
            uuid: user.id,
            signOut: signOut,
            deleteAccount: deleteAccount
        )
    }
    #endif

    func activateCloudAccount(
        email: String,
        uuid: UUID,
        signOut: @escaping () -> Void,
        deleteAccount: (() -> Void)? = nil
    ) {
        PersistenceController.invalidateBookmarkSession()
        isLoggedIn = false
        activationError = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        pendingActivation = (cleanEmail, uuid, signOut)
        do {
            try migrateIdentity(persistenceController, cleanEmail, uuid)
            // Publish a stable owner only after both migration steps commit.
            UserDefaults.standard.set(uuid.uuidString, forKey: "LoggedInUserUUID")
            if cleanEmail.isEmpty {
                UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
            } else {
                UserDefaults.standard.set(cleanEmail, forKey: "LoggedInUserEmail")
            }
            currentUserUUID = uuid
            cloudSignOut = signOut
            cloudDeleteAccount = deleteAccount
            isLoggedIn = true
            pendingActivation = nil
        } catch {
            activationError = error
        }
    }

    func retryCloudActivation() {
        guard let pendingActivation else { return }
        activateCloudAccount(email: pendingActivation.email, uuid: pendingActivation.uuid,
                             signOut: pendingActivation.signOut)
    }

    func abandonCloudActivation() {
        let signOut = pendingActivation?.signOut
        pendingActivation = nil
        activationError = nil
        signOut?()
    }

    func clearCloudAccount() {
        pendingActivation = nil
        activationError = nil
        PersistenceController.invalidateBookmarkSession()
        cloudSignOut = nil
        cloudDeleteAccount = nil
        currentUserUUID = nil
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        isLoggedIn = false
    }

    func deleteAccount() {
        PersistenceController.invalidateBookmarkSession()
        if let cloudDeleteAccount {
            cloudDeleteAccount()
            clearCloudAccount()
            return
        }
        clearCloudAccount()
    }

    func logout() {
        PersistenceController.invalidateBookmarkSession()
        if let cloudSignOut { cloudSignOut(); return }
        currentUserUUID = nil
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        isLoggedIn = false
    }
}
