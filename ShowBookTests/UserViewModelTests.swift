//
//  UserViewModelTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
@testable import ShowBook
import CoreData

final class UserViewModelTests: XCTestCase {
    var viewModel: UserViewModel!
    var mockPersistenceController: PersistenceController!
    
    override func setUpWithError() throws {
            try super.setUpWithError()
        mockPersistenceController = PersistenceController.shared
        mockPersistenceController.container = PersistenceController.createInMemoryPersistentContainer()
        }
    
    override func setUp() {
        super.setUp()
        //        let mockContainer = createInMemoryPersistentContainer()
        //        mockPersistenceController = PersistenceController(container: mockContainer)
        viewModel = UserViewModel()
        viewModel.setUpPersistenceController(controller: mockPersistenceController)
    }
    
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        viewModel = nil
        mockPersistenceController.deleteUser(email: "user@example.com")
        mockPersistenceController = nil
        
    }
    
    func testCheck_LoginStatusWhenUserIsLoggedIn() {
        // Given
        let email = "user@example.com"
        UserDefaults.standard.set(email, forKey: "LoggedInUserEmail")
        
        // Save user and then test the login status
        if mockPersistenceController.saveUser(email: email, password: "Qwe@12345") {
            
                self.viewModel.checkLoginStatus()

                XCTAssertTrue(self.viewModel.isLoggedIn, "User should be logged in when a valid email is found in UserDefaults and the user is successfully logged in.")
        } else {
            XCTAssertFalse(mockPersistenceController.doesUserExist(email: email), "User is not saved")
        }
    }

    
    func testCheck_LoginStatusWhenUserIsNotLoggedIn() {
        let email = "user@example.com"
        UserDefaults.standard.set(email, forKey: "LoggedInUserEmail")
        if mockPersistenceController.saveUser(email: email, password: "Qwe@12345"){
            self.mockPersistenceController.logOutUser(email: email)
            self.viewModel.checkLoginStatus()
            print("testCheck_LoginStatusWhenUserIsNotLoggedIn ========= ",self.viewModel.isLoggedIn)
            XCTAssertFalse(self.viewModel.isLoggedIn, "User should not be logged in when no user is found in the persistence controller.")
        }else{
            XCTAssertFalse(mockPersistenceController.doesUserExist(email: email), "User is not saved")
        }
    }
    
    func testCheck_LoginStatusWhenNoEmailInUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        self.viewModel.checkLoginStatus()
        print("testCheck_LoginStatusWhenNoEmailInUserDefaults ========= ",self.viewModel.isLoggedIn)
        XCTAssertFalse(self.viewModel.isLoggedIn, "User should not be logged in when no email is found in UserDefaults.")
    }
    
    func testCheck_Logout() {
        let email = "user@example.com"
        UserDefaults.standard.set(email, forKey: "LoggedInUserEmail")
        if mockPersistenceController.saveUser(email: email, password: "Qwe@12345"){
            self.viewModel.checkLoginStatus()
            self.viewModel.logout()
            print("testCheck_Logout ========= ",self.viewModel.isLoggedIn)
            XCTAssertNil(UserDefaults.standard.value(forKey: "LoggedInUserEmail"), "LoggedInUserEmail should be removed from UserDefaults after logout.")
            XCTAssertFalse(self.viewModel.isLoggedIn, "User should be logged out.")
        }
    }
    
//    func createInMemoryPersistentContainer() -> NSPersistentContainer {
//        let container = NSPersistentContainer(name: "ShowBook")
//        let description = NSPersistentStoreDescription()
//        description.type = NSInMemoryStoreType
//        container.persistentStoreDescriptions = [description]
//        
//        container.loadPersistentStores { (storeDescription, error) in
//            if let error = error {
//                fatalError("Error loading Core Data stores: \(error)")
//            }
//        }
//        
//        return container
//    }
    
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
