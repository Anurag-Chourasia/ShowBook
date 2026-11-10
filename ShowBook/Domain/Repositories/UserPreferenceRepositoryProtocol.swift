//
//  UserPreferenceRepositoryProtocol.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 10/11/26.
//

import Foundation

protocol UserPreferenceRepositoryProtocol: AnyObject {
    func saveCountryModel(_ countryModel: CountryModel)
    func saveDefaultCountryName(selectedCountryName: String)
    func fetchSelectedCountryName() -> String?
    func fetchCountryModel() -> CountryModel?
}
