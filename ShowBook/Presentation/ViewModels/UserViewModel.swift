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
    var persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        checkLoginStatus()
    }
    
    func setUpPersistenceController(controller: PersistenceController) {
        persistenceController = controller
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        guard pendingActivation == nil else { isLoggedIn = false; return }
        if let uuidString = UserDefaults.standard.string(forKey: "LoggedInUserUUID"),
           let uuid = UUID(uuidString: uuidString) {
            currentUserUUID = uuid
            if cloudSignOut != nil {
                isLoggedIn = true
                return
            }
        } else {
            currentUserUUID = nil
        }

        guard let userEmail = UserDefaults.standard.string(forKey: "LoggedInUserEmail") else {
            isLoggedIn = false
            return
        }
        isLoggedIn = checkIfUserIsLoggedIn(email: userEmail.lowercased())
    }
    
    private func checkIfUserIsLoggedIn(email: String) -> Bool {
        if let fetchUser = persistenceController.fetchUser(email: email) {
            return fetchUser.isSuccessfullyLoggedIn
        }
        return false
    }

    #if canImport(AuthKit)
    func activateCloudAccount(user: AuthUser, signOut: @escaping () -> Void) {
        activateCloudAccount(email: user.email ?? "", uuid: user.id, signOut: signOut)
    }
    #endif

    func activateCloudAccount(email: String, uuid: UUID, signOut: @escaping () -> Void) {
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
        currentUserUUID = nil
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        isLoggedIn = false
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
