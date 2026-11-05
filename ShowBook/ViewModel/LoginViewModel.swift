import LocalizationKit
//
//  LoginViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var showAlert = false
    @Published var isLoading = false

    var persistenceController = PersistenceController.shared
    
    func setUpPersistenceController(controller : PersistenceController){
        persistenceController = controller
    }
    
    func handleLogin(userViewModel: UserViewModel) {
        guard !isLoading else { return }
        showAlert = false
        errorMessage = ""
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = String(\ShowBookStrings.errorEmptyFields)
            showAlert = true
            return
        }
        guard isValidEmail(email) else {
            errorMessage = String(\ShowBookStrings.errorInvalidEmail)
            showAlert = true
            return
        }
        guard isValidPassword(password) else {
            errorMessage = String(\ShowBookStrings.errorLoginPassword)
            showAlert = true
            return
        }
        isLoading = true
        let loginEmail = email.lowercased()
        persistenceController.authenticate(email: loginEmail, password: password) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                PersistenceController.invalidateBookmarkSession()
                UserDefaults.standard.setValue(loginEmail, forKey: "LoggedInUserEmail")
                self.password = ""
                withAnimation(.easeInOut) { userViewModel.isLoggedIn = true }
            case .failure(let error):
                self.errorMessage = (error as? CredentialError)?.localizedDescription
                    ?? String(\ShowBookStrings.errorSaveLogin)
                self.showAlert = true
            }
        }
    }
}
