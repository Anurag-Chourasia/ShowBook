//
//  UserPreferenceRepositoryImpl.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 10/11/26.
//

import Foundation

final class UserPreferenceRepositoryImpl: UserPreferenceRepositoryProtocol {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    func saveCountryModel(_ countryModel: CountryModel) {
        persistenceController.saveCountryModel(countryModel)
    }

    func saveDefaultCountryName(selectedCountryName: String) {
        persistenceController.saveDefaultCountryName(selectedCountryName: selectedCountryName)
    }

    func fetchSelectedCountryName() -> String? {
        persistenceController.fetchSelectedCountryName()
    }

    func fetchCountryModel() -> CountryModel? {
        persistenceController.fetchCountryModel()
    }
}
