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
        isLoading = true
        if !email.isEmpty && !password.isEmpty {
            showAlert = !isValidEmail(email)
            if !showAlert {
                if isValidPassword(password) {
                    errorMessage = ""
                    if let existingUser = persistenceController.fetchUser(email: email.lowercased()) {
                        if existingUser.password == password {
                            UserDefaults.standard.setValue(email.lowercased(), forKey: "LoggedInUserEmail")
                            persistenceController.logInUser(email: email.lowercased())
                            withAnimation(.easeInOut) {
                                userViewModel.isLoggedIn = true
                            }
                        } else {
                            showAlert = true
                            errorMessage = "Wrong Password"
                        }
                    } else {
                        showAlert = true
                        errorMessage = "Sign Up first to login"
                    }
                } else {
                    showAlert = true
                    errorMessage = "Password Must contain 8 characters minimum including 1 alphabet, 1 number, and 1 special character like @,#"
                }
            } else {
                errorMessage = "Enter a valid email"
                showAlert = true
            }
        } else {
            errorMessage = "Fields cannot be empty"
            showAlert = true
        }
        isLoading = false
    }
}
