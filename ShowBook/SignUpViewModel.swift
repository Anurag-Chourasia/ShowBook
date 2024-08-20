//
//  SignUpViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import SwiftUI
import Combine

class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var showAlert = false
    @Published var isLoading = false
    @Published var countries: [String] = []
    @Published var selectedCountryIndex: Int = 0
    
    private var api = NetworkClass()
    var persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    func setUpPersistenceController(controller : PersistenceController){
        persistenceController = controller
    }
    
    func handleSignUp(userViewModel: UserViewModel) {
        isLoading = true
        if !email.isEmpty && !password.isEmpty {
            if !isValidEmail(email) {
                DispatchQueue.main.async {
                    self.errorMessage = "Enter a valid email"
                    self.showAlert = true
                    self.isLoading = false
                }
            } else if !isValidPassword(password) {
                DispatchQueue.main.async {
                    self.errorMessage = "Password must contain 8 characters minimum including 1 alphabet, 1 number, and 1 special character like @,#"
                    self.showAlert = true
                    self.isLoading = false
                }
            } else {
                UIApplication.shared.endEditing()
                performSignUp(userViewModel: userViewModel)
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Fields cannot be empty"
                self.showAlert = true
                self.isLoading = false
            }
        }
    }
    
    private func performSignUp(userViewModel: UserViewModel) {
        DispatchQueue.main.async {
            if self.persistenceController.saveUser(email: self.email.lowercased(), password: self.password) {
                UserDefaults.standard.setValue(self.email.lowercased(), forKey: "LoggedInUserEmail")
                self.isLoading = false
                withAnimation(.easeInOut) {
                    userViewModel.isLoggedIn = true
                }
            } else {
                self.errorMessage = "User with this email already exists"
                self.showAlert = true
                self.isLoading = false
            }
        }
    }
    
    func loadData() {
        isLoading = true
        if let savedCountryModel = persistenceController.fetchCountryModel(),
           let selectedCountryName = persistenceController.fetchSelectedCountryName() {
            DispatchQueue.main.async {
                self.countries = savedCountryModel.data.map { $0.value.country }.sorted()
                if !self.countries.isEmpty {
                    self.selectedCountryIndex = self.countries.firstIndex(of: selectedCountryName) ?? 0
                }
                self.isLoading = false
            }
        } else {
            fetchCountriesAndIPDetails()
        }
    }
    
    private func fetchCountriesAndIPDetails() {
        api.fetchCountries { [weak self] fetchedCountries, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showAlert = true
                    self.isLoading = false
                }
            } else if let fetchedCountries = fetchedCountries {
                DispatchQueue.main.async {
                    self.countries = fetchedCountries.data.map { $0.value.country }.sorted()
                }
                self.api.fetchIPDetails { response, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = "Error fetching IP details: \(error.localizedDescription)"
                            self.showAlert = true
                        }
                    } else if let response = response {
                        DispatchQueue.main.async {
                            self.selectedCountryIndex = self.countries.firstIndex(of: response.country) ?? 0
                            self.persistenceController.saveCountryModel(fetchedCountries)
                            let name = self.countries[self.selectedCountryIndex]
                            self.persistenceController.saveDefaultCountryName(selectedCountryName: name)
                            self.isLoading = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Unexpected error"
                            self.showAlert = true
                            self.isLoading = false
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unexpected error"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
}

