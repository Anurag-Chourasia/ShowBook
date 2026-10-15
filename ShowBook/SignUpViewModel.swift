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
    
    private let api: NetworkClass

    init(api: NetworkClass = NetworkClass()) { self.api = api }
    var persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    func setUpPersistenceController(controller : PersistenceController){
        persistenceController = controller
    }
    
    func handleSignUp(userViewModel: UserViewModel) {
        guard !isLoading else { return }
        showAlert = false
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
        let signupEmail = email.lowercased()
        persistenceController.registerUser(email: signupEmail, password: password) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                UserDefaults.standard.setValue(signupEmail, forKey: "LoggedInUserEmail")
                self.password = ""
                withAnimation(.easeInOut) { userViewModel.isLoggedIn = true }
            case .failure(let error):
                self.errorMessage = (error as? CredentialError)?.localizedDescription
                    ?? "Unable to save account. Please try again."
                self.showAlert = true
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
            DispatchQueue.main.async {
                guard let self else { return }
                guard let fetchedCountries, error == nil else {
                    self.errorMessage = error?.localizedDescription ?? "Unexpected error"
                    self.showAlert = true
                    self.isLoading = false
                    return
                }
                self.countries = fetchedCountries.data.map { $0.value.country }.sorted()
                self.selectedCountryIndex = 0
                guard let firstCountry = self.countries.first else {
                    self.errorMessage = "No countries available"
                    self.showAlert = true
                    self.isLoading = false
                    return
                }
                self.persistenceController.saveCountryModel(fetchedCountries)
                self.persistenceController.saveDefaultCountryName(selectedCountryName: firstCountry)
                self.api.fetchIPDetails { [weak self] response, error in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        defer { self.isLoading = false }
                        if let error {
                            self.errorMessage = "Error fetching IP details: \(error.localizedDescription)"
                            self.showAlert = true
                        } else if let response {
                            self.selectedCountryIndex = self.countries.firstIndex(of: response.country) ?? 0
                            if self.countries.indices.contains(self.selectedCountryIndex) {
                                self.persistenceController.saveDefaultCountryName(selectedCountryName: self.countries[self.selectedCountryIndex])
                            }
                        } else {
                            self.errorMessage = "Unexpected error"
                            self.showAlert = true
                        }
                    }
                }
            }
        }
    }
}
