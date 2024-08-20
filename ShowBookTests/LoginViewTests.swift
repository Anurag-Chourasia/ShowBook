//
//  LoginViewTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
@testable import ShowBook
import CoreData

final class LoginViewModelTests: XCTestCase {
    
    var loginViewModel: LoginViewModel!
    var userViewModel: UserViewModel!
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
        userViewModel = UserViewModel()
        userViewModel.setUpPersistenceController(controller: mockPersistenceController)
        mockPersistenceController.deleteUser(email: "test@example.com")
        loginViewModel = LoginViewModel()
        loginViewModel.setUpPersistenceController(controller: mockPersistenceController)
        
    }
    
    override func tearDown() {
        loginViewModel = nil
        userViewModel = nil
        mockPersistenceController = nil
        super.tearDown()
    }
    
    func testValidLogin() {
        if mockPersistenceController.saveUser(email: "test@example.com", password: "ValidPassword123@"){
            
            loginViewModel.email = "test@example.com"
            loginViewModel.password = "ValidPassword123@"
            loginViewModel.handleLogin(userViewModel: userViewModel)
            
            XCTAssertTrue(userViewModel.isLoggedIn)
            XCTAssertFalse(loginViewModel.showAlert)
        }else{
            XCTAssertFalse(mockPersistenceController.doesUserExist(email: "test@example.com"))
        }
    }
    
    func testInValidLogin() {
        if mockPersistenceController.saveUser(email: "test@example.com", password: "ValidPassword123@"){
            
            loginViewModel.email = "test1@example.com"
            loginViewModel.password = "ValidPassword123@"
            loginViewModel.handleLogin(userViewModel: userViewModel)
            
            XCTAssertFalse(userViewModel.isLoggedIn)
            XCTAssertTrue(loginViewModel.showAlert)
        }else{
            XCTAssertFalse(mockPersistenceController.doesUserExist(email: "test@example.com"))
        }
    }
    
    func testInvalidEmail() {
        if mockPersistenceController.saveUser(email: "test@example.com", password: "ValidPassword123@"){
            loginViewModel.email = "invalidemail"
            loginViewModel.password = "ValidPassword123@"
            loginViewModel.handleLogin(userViewModel: userViewModel)
            
            XCTAssertFalse(userViewModel.isLoggedIn)
            XCTAssertEqual(loginViewModel.errorMessage, "Enter a valid email")
            XCTAssertTrue(loginViewModel.showAlert)
        }else{
            XCTAssertFalse(mockPersistenceController.doesUserExist(email: "test@example.com"))
        }
    }
    
    func testInvalidPassword() {
        if mockPersistenceController.saveUser(email: "test@example.com", password: "ValidPassword123@"){
            loginViewModel.email = "test@example.com"
            loginViewModel.password = "short"
            loginViewModel.handleLogin(userViewModel: userViewModel)
            
            XCTAssertFalse(userViewModel.isLoggedIn)
            XCTAssertEqual(loginViewModel.errorMessage, "Password Must contain 8 characters minimum including 1 alphabet, 1 number, and 1 special character like @,#")
            XCTAssertTrue(loginViewModel.showAlert)
        }else{
            XCTAssertFalse(mockPersistenceController.doesUserExist(email: "test@example.com"))
        }
    }
    
    func testEmptyFields() {
        if mockPersistenceController.saveUser(email: "test@example.com", password: "ValidPassword123@"){
            loginViewModel.email = ""
            loginViewModel.password = ""
            loginViewModel.handleLogin(userViewModel: userViewModel)
            
            XCTAssertFalse(userViewModel.isLoggedIn)
            XCTAssertEqual(loginViewModel.errorMessage, "Fields cannot be empty")
            XCTAssertTrue(loginViewModel.showAlert)
        }else{
            XCTAssertFalse(mockPersistenceController.doesUserExist(email: "test@example.com"))
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

