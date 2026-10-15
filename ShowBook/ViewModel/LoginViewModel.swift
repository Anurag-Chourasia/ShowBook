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
            errorMessage = "Fields cannot be empty"
            showAlert = true
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Enter a valid email"
            showAlert = true
            return
        }
        guard isValidPassword(password) else {
            errorMessage = "Password Must contain 8 characters minimum including 1 alphabet, 1 number, and 1 special character like @,#"
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
                UserDefaults.standard.setValue(loginEmail, forKey: "LoggedInUserEmail")
                self.password = ""
                withAnimation(.easeInOut) { userViewModel.isLoggedIn = true }
            case .failure(let error):
                self.errorMessage = (error as? CredentialError)?.localizedDescription
                    ?? "Unable to save login. Please try again."
                self.showAlert = true
            }
        }
    }
}
