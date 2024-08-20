//
//  SignUpViewTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
import Combine
import CoreData
@testable import ShowBook

final class SignUpViewModelTests: XCTestCase {

    var signUpViewModel: SignUpViewModel!
    var userViewModel: UserViewModel!
    var mockPersistenceController: PersistenceController!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
            try super.setUpWithError()
        mockPersistenceController = PersistenceController.shared
        mockPersistenceController.container = PersistenceController.createInMemoryPersistentContainer()
        }
    override func setUp() {
        super.setUp()
//        let mockContainer = createInMemoryPersistentContainer()
//        mockPersistenceController = PersistenceController(container: mockContainer)
        mockPersistenceController.deleteUser(email: "test@example.com")
        
        userViewModel = UserViewModel()
        userViewModel.setUpPersistenceController(controller: mockPersistenceController)
        signUpViewModel = SignUpViewModel()
        signUpViewModel.setUpPersistenceController(controller: mockPersistenceController)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        signUpViewModel = nil
        userViewModel = nil
        mockPersistenceController = nil
        cancellables = nil
        super.tearDown()
    }

    func testValidSignUp() {
        let expectation = XCTestExpectation(description: "Valid sign up should succeed")

        signUpViewModel.email = "test@example.com".lowercased()
        signUpViewModel.password = "ValidPassword123@"
        signUpViewModel.handleSignUp(userViewModel: userViewModel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertFalse(self.signUpViewModel.isLoading)
            XCTAssertTrue(self.userViewModel.isLoggedIn)
            XCTAssertFalse(self.signUpViewModel.showAlert)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }

    func testSignUpWithInvalidEmail() {
        let expectation = XCTestExpectation(description: "Sign up with invalid email should show alert")

        signUpViewModel.email = "invalidemail"
        signUpViewModel.password = "ValidPassword123@"
        signUpViewModel.handleSignUp(userViewModel: userViewModel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.signUpViewModel.errorMessage, "Enter a valid email")
            XCTAssertTrue(self.signUpViewModel.showAlert)
            XCTAssertFalse(self.userViewModel.isLoggedIn)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }

    func testSignUpWithInvalidPassword() {
        let expectation = XCTestExpectation(description: "Sign up with invalid password should show alert")

        signUpViewModel.email = "test@example.com"
        signUpViewModel.password = "short"
        signUpViewModel.handleSignUp(userViewModel: userViewModel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.signUpViewModel.errorMessage, "Password must contain 8 characters minimum including 1 alphabet, 1 number, and 1 special character like @,#")
            XCTAssertTrue(self.signUpViewModel.showAlert)
            XCTAssertFalse(self.userViewModel.isLoggedIn)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }

    func testSignUpWithEmptyFields() {
        let expectation = XCTestExpectation(description: "Sign up with empty fields should show alert")

        signUpViewModel.email = ""
        signUpViewModel.password = ""
        signUpViewModel.handleSignUp(userViewModel: userViewModel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.signUpViewModel.errorMessage, "Fields cannot be empty")
            XCTAssertTrue(self.signUpViewModel.showAlert)
            XCTAssertFalse(self.userViewModel.isLoggedIn)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    class MockNetworkClass: NetworkClass {

        override func fetchCountries(completion: @escaping (CountryModel?, Error?) -> Void) {

            let countriesData: [String: Datum] = [
                "IN": Datum(country: "India", region: .asia),
                "TH": Datum(country: "Thailand", region: .asia),
                "TG": Datum(country: "Togo", region: .africa),
                "VN": Datum(country: "Viet Nam", region: .asia),
                "KE": Datum(country: "Kenya", region: .africa),
                "EG": Datum(country: "Egypt", region: .africa),
                "SG": Datum(country: "Singapore", region: .asia),
                "TM": Datum(country: "Turkmenistan", region: .asia),
                "BD": Datum(country: "Bangladesh", region: .asia),
                "LR": Datum(country: "Liberia", region: .africa),
                "HK": Datum(country: "Hong Kong", region: .asia),
                "ER": Datum(country: "Eritrea", region: .africa),
                "BN": Datum(country: "Brunei Darussalam", region: .asia),
                "TD": Datum(country: "Chad", region: .africa),
                "UG": Datum(country: "Uganda", region: .africa),
                "AM": Datum(country: "Armenia", region: .asia),
                "CF": Datum(country: "Central African Republic (the)", region: .africa),
                "SL": Datum(country: "Sierra Leone", region: .africa),
                "MO": Datum(country: "Macao", region: .asia),
                "SZ": Datum(country: "Eswatini", region: .africa),
                "BT": Datum(country: "Bhutan", region: .asia),
                "ZW": Datum(country: "Zimbabwe", region: .africa),
                "KR": Datum(country: "Korea (the Republic of)", region: .asia),
                "GA": Datum(country: "Gabon", region: .africa),
                "ZA": Datum(country: "South Africa", region: .africa),
                "LY": Datum(country: "Libya", region: .africa),
                "JP": Datum(country: "Japan", region: .asia),
                "NA": Datum(country: "Namibia", region: .africa),
                "MN": Datum(country: "Mongolia", region: .asia),
                "BZ": Datum(country: "Belize", region: .centralAmerica),
                "KM": Datum(country: "Comoros (the)", region: .africa),
                "SH": Datum(country: "Saint Helena, Ascension and Tristan da Cunha", region: .africa),
                "MG": Datum(country: "Madagascar", region: .africa),
                "GH": Datum(country: "Ghana", region: .africa),
                "DZ": Datum(country: "Algeria", region: .africa),
                "PK": Datum(country: "Pakistan", region: .asia),
                "MZ": Datum(country: "Mozambique", region: .africa),
                "TF": Datum(country: "French Southern Territories (the)", region: .antarctic),
                "LA": Datum(country: "Lao People's Democratic Republic (the)", region: .asia),
                "DJ": Datum(country: "Djibouti", region: .africa),
                "KZ": Datum(country: "Kazakhstan", region: .asia),
                "AF": Datum(country: "Afghanistan", region: .asia),
                "MV": Datum(country: "Maldives", region: .asia),
                "MM": Datum(country: "Myanmar", region: .asia),
                "GS": Datum(country: "South Georgia and the South Sandwich Islands", region: .antarctic),
                "HM": Datum(country: "Heard Island and McDonald Islands", region: .antarctic),
                "ET": Datum(country: "Ethiopia", region: .africa),
                "CN": Datum(country: "China", region: .asia),
                "CV": Datum(country: "Cabo Verde", region: .africa),
                "SS": Datum(country: "South Sudan", region: .africa),
                "CM": Datum(country: "Cameroon", region: .africa),
                "GN": Datum(country: "Guinea", region: .africa),
                "SO": Datum(country: "Somalia", region: .africa),
                "CI": Datum(country: "Côte d'Ivoire", region: .africa),
                "GM": Datum(country: "Gambia (the)", region: .africa),
                "TZ": Datum(country: "Tanzania, the United Republic of", region: .africa),
                "MR": Datum(country: "Mauritania", region: .africa),
                "ZM": Datum(country: "Zambia", region: .africa),
                "ID": Datum(country: "Indonesia", region: .asia),
                "KG": Datum(country: "Kyrgyzstan", region: .asia),
                "EH": Datum(country: "Western Sahara*", region: .africa),
                "CG": Datum(country: "Congo (the)", region: .africa),
                "MW": Datum(country: "Malawi", region: .africa),
                "YT": Datum(country: "Mayotte", region: .africa),
                "BI": Datum(country: "Burundi", region: .africa),
                "PH": Datum(country: "Philippines (the)", region: .asia),
                "KP": Datum(country: "Korea (the Democratic People's Republic of)", region: .asia),
                "NP": Datum(country: "Nepal", region: .asia),
                "SD": Datum(country: "Sudan (the)", region: .africa),
                "ML": Datum(country: "Mali", region: .africa),
                "AQ": Datum(country: "Antarctica", region: .antarctic),
                "MY": Datum(country: "Malaysia", region: .asia),
                "BV": Datum(country: "Bouvet Island", region: .antarctic),
                "CD": Datum(country: "Congo (the Democratic Republic of the)", region: .africa),
                "UZ": Datum(country: "Uzbekistan", region: .asia),
                "TL": Datum(country: "Timor-Leste", region: .asia),
                "AO": Datum(country: "Angola", region: .africa),
                "BJ": Datum(country: "Benin", region: .africa),
                "NG": Datum(country: "Nigeria", region: .africa),
                "TJ": Datum(country: "Tajikistan", region: .asia),
                "MU": Datum(country: "Mauritius", region: .africa),
                "TW": Datum(country: "Taiwan (Province of China)", region: .asia),
                "KH": Datum(country: "Cambodia", region: .asia),
                "LK": Datum(country: "Sri Lanka", region: .asia),
                "IO": Datum(country: "British Indian Ocean Territory (the)", region: .asia),
                "LS": Datum(country: "Lesotho", region: .africa),
                "SN": Datum(country: "Senegal", region: .africa),
                "RW": Datum(country: "Rwanda", region: .africa),
                "BW": Datum(country: "Botswana", region: .africa),
                "RE": Datum(country: "Réunion", region: .africa),
                "TN": Datum(country: "Tunisia", region: .africa),
                "NE": Datum(country: "Niger (the)", region: .africa),
                "SC": Datum(country: "Seychelles", region: .africa),
                "GW": Datum(country: "Guinea-Bissau", region: .africa),
                "GQ": Datum(country: "Equatorial Guinea", region: .africa),
                "MA": Datum(country: "Morocco", region: .africa),
                "GE": Datum(country: "Georgia", region: .asia),
                "AZ": Datum(country: "Azerbaijan", region: .asia),
                "BF": Datum(country: "Burkina Faso", region: .africa),
                "ST": Datum(country: "Sao Tome and Principe", region: .africa)
            ]
            
            let mockCountries = CountryModel(
                status: "OK",
                statusCode: 200,
                version: "1.0",
                access: "public",
                total: countriesData.count,
                offset: 0,
                limit: countriesData.count,
                data: countriesData
            )
            completion(mockCountries, nil)
        }

        override func fetchIPDetails(completion: @escaping (IPApiResponseModel?, Error?) -> Void) {
                 let mockIPDetails = IPApiResponseModel(
                    status: "success",
                    country: "India",
                    countryCode: "IN",
                    region: "WB",
                    regionName: "West Bengal",
                    city: "Kolkata",
                    zip: "700034",
                    lat: 22.518,
                    lon: 88.3832,
                    timezone: "Asia/Kolkata",
                    isp: "Reliance Jio Infocomm Limited",
                    org: "Reliance Jio Infocomm Limited",
                    asDescription: "AS55836 Reliance Jio Infocomm Limited",
                    query: "49.37.42.255"
                )
                completion(mockIPDetails, nil)
            }
    }
    
    func createInMemoryPersistentContainer() -> NSPersistentContainer {
        let modelURL = Bundle.main.url(forResource: "ShowBook", withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        let container = NSPersistentContainer(name: "ShowBook", managedObjectModel: managedObjectModel)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Error loading Core Data stores: \(error)")
            }
        }
        
        return container
    }
}
