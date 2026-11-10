import LocalizationKit
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
    private var countryTask: Task<Void, Never>?
    private var countryRequestID = UUID()

    deinit { countryTask?.cancel() }

    func cancelCountryRequest() {
        countryRequestID = UUID()
        countryTask?.cancel()
        countryTask = nil
        isLoading = false
    }

    private let regionCode: String?
    var persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()

    init(
        api: NetworkClass = NetworkClass(),
        regionCode: String? = Locale.current.region?.identifier,
        persistenceController: PersistenceController = .shared
    ) {
        self.api = api
        self.regionCode = regionCode
        self.persistenceController = persistenceController
    }
    
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
                    self.errorMessage = String(\ShowBookStrings.errorInvalidEmail)
                    self.showAlert = true
                    self.isLoading = false
                }
            } else if !isValidPassword(password) {
                DispatchQueue.main.async {
                    self.errorMessage = String(\ShowBookStrings.errorSignupPassword)
                    self.showAlert = true
                    self.isLoading = false
                }
            } else {
                UIApplication.shared.endEditing()
                performSignUp(userViewModel: userViewModel)
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = String(\ShowBookStrings.errorEmptyFields)
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
                    ?? String(\ShowBookStrings.errorSaveAccount)
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
            loadCountries()
        }
    }
    
    private func loadCountries() {
        countryTask?.cancel()
        countryRequestID = UUID()
        isLoading = true
        let id = countryRequestID
        countryTask = api.fetchCountries { [weak self] fetchedCountries, error in
            DispatchQueue.main.async {
                guard let self, self.countryRequestID == id else { return }
                self.countryTask = nil
                guard let fetchedCountries, error == nil else {
                    if let error {
                        self.errorMessage = DashboardViewModel.localizedErrorMessage(for: error)
                    } else {
                        self.errorMessage = String(\ShowBookStrings.errorUnexpected)
                    }
                    self.showAlert = true
                    self.isLoading = false
                    return
                }
                self.countries = fetchedCountries.data.map { $0.value.country }.sorted()
                self.selectedCountryIndex = 0
                guard let firstCountry = self.countries.first else {
                    self.errorMessage = String(\ShowBookStrings.errorCountries)
                    self.showAlert = true
                    self.isLoading = false
                    return
                }
                self.persistenceController.saveCountryModel(fetchedCountries)
                let preferredCountry = self.regionCode.flatMap { fetchedCountries.data[$0]?.country } ?? firstCountry
                self.selectedCountryIndex = self.countries.firstIndex(of: preferredCountry) ?? 0
                self.persistenceController.saveDefaultCountryName(selectedCountryName: preferredCountry)
                self.isLoading = false
            }
        }
    }
}
