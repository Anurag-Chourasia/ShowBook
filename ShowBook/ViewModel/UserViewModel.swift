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
    var cloudSignOut: (() -> Void)?
    var persistenceController = PersistenceController.shared
    
    init() {
        checkLoginStatus()
    }
    
    func setUpPersistenceController(controller: PersistenceController) {
        persistenceController = controller
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
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
        cloudSignOut = signOut
        currentUserUUID = user.id
        UserDefaults.standard.set(user.id.uuidString, forKey: "LoggedInUserUUID")
        let email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if !email.isEmpty {
            UserDefaults.standard.set(email, forKey: "LoggedInUserEmail")
            _ = try? PersistenceController.linkLocalAccount(email: email, toUUID: user.id, in: persistenceController.container.viewContext)
            _ = try? PersistenceController.migrateBookmarks(fromEmail: email, toUUID: user.id, in: persistenceController.container.viewContext)
        } else {
            UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        }
        isLoggedIn = true
    }
    #endif

    func activateCloudAccount(email: String, uuid: UUID? = nil, signOut: @escaping () -> Void) {
        cloudSignOut = signOut
        let resolvedUUID = uuid ?? UUID()
        currentUserUUID = resolvedUUID
        UserDefaults.standard.set(resolvedUUID.uuidString, forKey: "LoggedInUserUUID")
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        UserDefaults.standard.set(cleanEmail, forKey: "LoggedInUserEmail")
        _ = try? PersistenceController.linkLocalAccount(email: cleanEmail, toUUID: resolvedUUID, in: persistenceController.container.viewContext)
        _ = try? PersistenceController.migrateBookmarks(fromEmail: cleanEmail, toUUID: resolvedUUID, in: persistenceController.container.viewContext)
        isLoggedIn = true
    }

    func clearCloudAccount() {
        cloudSignOut = nil
        currentUserUUID = nil
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        isLoggedIn = false
    }

    func logout() {
        if let cloudSignOut { cloudSignOut(); return }
        currentUserUUID = nil
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        isLoggedIn = false
    }
}
