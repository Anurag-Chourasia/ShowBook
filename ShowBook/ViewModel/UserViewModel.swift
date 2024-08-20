//
//  UserViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    var persistenceController = PersistenceController.shared
    
    init() {
        checkLoginStatus()
    }
    
    func setUpPersistenceController(controller : PersistenceController){
        persistenceController = controller
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        guard let userEmail = UserDefaults.standard.value(forKey: "LoggedInUserEmail") as? String else {
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
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        isLoggedIn = false
    }
}
