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
    var cloudSendOTP: (() async throws -> Void)?
    var cloudChangePassword: ((String, String, String) async throws -> Void)?
    var cloudUpdatePassword: ((String) async throws -> Void)?
    var persistenceController: PersistenceController

    var currentUserEmail: String? { UserDefaults.standard.string(forKey: "LoggedInUserEmail") }

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
    convenience init() { self.init(persistenceController: PersistenceController.inMemory()) }
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
            #if canImport(AuthKit)
            if cloudUser == nil {
                cloudUser = AuthUser(
                    id: uuid, email: currentUserEmail,
                    firstName: UserDefaults.standard.string(forKey: "LoggedInUserFirstName"),
                    lastName: UserDefaults.standard.string(forKey: "LoggedInUserLastName"),
                    phone: UserDefaults.standard.string(forKey: "LoggedInUserPhone")
                )
            }
            #endif
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
        if let phone = user.phone { UserDefaults.standard.set(phone, forKey: "LoggedInUserPhone") }
        if let first = user.firstName { UserDefaults.standard.set(first, forKey: "LoggedInUserFirstName") }
        if let last = user.lastName { UserDefaults.standard.set(last, forKey: "LoggedInUserLastName") }
        if let session {
            cloudUpdateProfile = { [weak self, weak session] email, first, last, phone in
                Task {
                    await session?.updateProfile(email: email, firstName: first, lastName: last, phone: phone)
                    await MainActor.run {
                        if let current = self?.cloudUser {
                            self?.cloudUser = AuthUser(
                                id: current.id, email: email ?? current.email,
                                firstName: first ?? current.firstName, lastName: last ?? current.lastName,
                                phone: phone ?? current.phone
                            )
                        }
                        if let phone { UserDefaults.standard.set(phone, forKey: "LoggedInUserPhone") }
                        if let first { UserDefaults.standard.set(first, forKey: "LoggedInUserFirstName") }
                        if let last { UserDefaults.standard.set(last, forKey: "LoggedInUserLastName") }
                    }
                }
            }
            cloudUpdatePassword = { [weak session] password in
                try await session?.updatePassword(password)
            }
            cloudSendOTP = { [weak session] in
                try await session?.sendPasswordResetOTP()
            }
            cloudChangePassword = { [weak session] current, new, otp in
                await session?.changePassword(currentPassword: current, newPassword: new, otpCode: otp)
            }
        }
        activateCloudAccount(
            email: user.email ?? "", uuid: user.id, signOut: signOut, deleteAccount: deleteAccount
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
        ["LoggedInUserUUID", "LoggedInUserEmail", "LoggedInUserPhone",
         "LoggedInUserFirstName", "LoggedInUserLastName"].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        #if canImport(AuthKit)
        cloudUser = nil
        #endif
        isLoggedIn = false
    }

    func deleteAccount() {
        PersistenceController.invalidateBookmarkSession()
        cloudDeleteAccount?()
        clearCloudAccount()
    }

    func logout() {
        PersistenceController.invalidateBookmarkSession()
        let keys = ["LoggedInUserPhone", "LoggedInUserFirstName", "LoggedInUserLastName"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        #if canImport(AuthKit)
        cloudUser = nil
        #endif
        if let cloudSignOut { cloudSignOut(); return }
        currentUserUUID = nil
        ["LoggedInUserUUID", "LoggedInUserEmail"].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        isLoggedIn = false
    }
}
