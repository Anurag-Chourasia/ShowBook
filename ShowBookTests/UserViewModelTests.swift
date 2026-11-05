//
//  UserViewModelTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
import UIKit
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

    
    func testCloudAccountBindsBookmarksAndDelegatesLogoutUntilConfirmed() {
        var requestedSignOut = false
        viewModel.activateCloudAccount(email: "Cloud@Example.com", uuid: UUID()) { requestedSignOut = true }
        XCTAssertTrue(viewModel.isLoggedIn)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "LoggedInUserEmail"), "cloud@example.com")
        viewModel.logout()
        XCTAssertTrue(requestedSignOut)
        XCTAssertTrue(viewModel.isLoggedIn, "A failed cloud sign-out must preserve the session")
        viewModel.clearCloudAccount()
        XCTAssertFalse(viewModel.isLoggedIn)
        XCTAssertNil(UserDefaults.standard.string(forKey: "LoggedInUserEmail"))
    }
}

@MainActor
final class AuthenticationFlagTests: XCTestCase {

    func testBrandColorsStayOpaqueInBothAppearances() throws {
        let names = ["BrandBackground", "BrandSurface", "BrandAction",
                     "AuthBackground", "AuthForeground", "AuthAction", "AuthOnAction"]
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for name in names {
                let color = try XCTUnwrap(UIColor(named: name, in: .main, compatibleWith: traits))
                XCTAssertEqual(color.resolvedColor(with: traits).cgColor.alpha, 1, accuracy: 0.001,
                               "\(name) must remain opaque")
            }
        }
    }

    func testAuthenticationIsOptInAndDeveloperPreferenceIsDebugOnly() {
        let defaults = UserDefaults.standard
        let key = "developer.authentication"
        let original = defaults.object(forKey: key)
        defer {
            if let original { defaults.set(original, forKey: key) } else { defaults.removeObject(forKey: key) }
        }
        defaults.removeObject(forKey: key)
        XCTAssertFalse(AppRuntime.authenticationEnabled)
        defaults.set(true, forKey: key)
        #if DEBUG
        XCTAssertTrue(AppRuntime.authenticationEnabled)
        #else
        XCTAssertFalse(AppRuntime.authenticationEnabled)
        #endif
        defaults.set(false, forKey: key)
        XCTAssertFalse(AppRuntime.authenticationEnabled)

        #if DEBUG
        defaults.set("stub", forKey: "developer.source")
        defaults.set("showcase", forKey: "developer.scenario")
        XCTAssertEqual(AppRuntime.stubScenario, "showcase")
        XCTAssertTrue(AppRuntime.isShowcaseMode)

        let subjectsURL = URL(string: "https://openlibrary.org/subjects/fiction.json")!
        let subjectsBody = ShowcaseStubProtocol.body(for: subjectsURL)
        XCTAssertNotNil(subjectsBody)
        XCTAssertTrue(subjectsBody?.contains("The Design of Everyday Things") == true)

        let searchURL = URL(string: "https://openlibrary.org/search.json?q=design")!
        let searchBody = ShowcaseStubProtocol.body(for: searchURL)
        XCTAssertNotNil(searchBody)
        XCTAssertTrue(searchBody?.contains("Clean Code") == true)

        defaults.removeObject(forKey: "developer.source")
        defaults.removeObject(forKey: "developer.scenario")
        #endif
    }
}

@MainActor
final class IdentityActivationRecoveryTests: XCTestCase {
    private enum InjectedFailure: Error { case link, save }
    private var persistence: PersistenceController!
    private var model: UserViewModel!
    private var previousEmail: Any?
    private var previousUUID: Any?
    private let email = "migration@example.com"

    override func setUpWithError() throws {
        previousEmail = UserDefaults.standard.object(forKey: "LoggedInUserEmail")
        previousUUID = UserDefaults.standard.object(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        persistence = PersistenceController(container: PersistenceController.createInMemoryPersistentContainer())
        model = UserViewModel()
        model.setUpPersistenceController(controller: persistence)
    }

    override func tearDownWithError() throws {
        model = nil
        persistence = nil
        UserDefaults.standard.set(previousEmail, forKey: "LoggedInUserEmail")
        UserDefaults.standard.set(previousUUID, forKey: "LoggedInUserUUID")
    }

    private func seed(owner: UUID? = nil) throws {
        let context = persistence.container.viewContext
        let user = try XCTUnwrap(NSEntityDescription.insertNewObject(forEntityName: "UserEntity", into: context) as? UserEntity)
        user.email = email
        user.userUUID = owner
        let book = try XCTUnwrap(NSEntityDescription.insertNewObject(forEntityName: "BookEntity", into: context) as? BookEntity)
        book.title = "Preserved legacy book"
        book.email = email
        book.userUUID = owner
        try context.save()
    }

    private func owners() throws -> (UUID?, [UUID?]) {
        let context = persistence.container.newBackgroundContext()
        return try context.performAndWait {
            let users = try context.fetch(UserEntity.fetchRequest())
            let books = try context.fetch(BookEntity.fetchRequest())
            return (users.first?.userUUID, books.map(\.userUUID))
        }
    }

    func testLinkFailureDoesNotPublishIdentityAndRetryUsesSameUUID() throws {
        try seed()
        let uuid = UUID()
        var attempts = 0
        model.migrateIdentity = { store, email, uuid in
            attempts += 1
            if attempts == 1 { throw InjectedFailure.link }
            try store.activateCloudIdentity(email: email, uuid: uuid)
        }
        model.activateCloudAccount(email: email, uuid: uuid) {}
        XCTAssertFalse(model.isLoggedIn)
        XCTAssertNotNil(model.activationError)
        XCTAssertNil(UserDefaults.standard.string(forKey: "LoggedInUserUUID"))
        XCTAssertNil(try owners().0)
        XCTAssertEqual(try owners().1, [nil])
        model.checkLoginStatus()
        XCTAssertFalse(model.isLoggedIn)

        model.retryCloudActivation()
        XCTAssertTrue(model.isLoggedIn)
        XCTAssertNil(model.activationError)
        XCTAssertEqual(model.currentUserUUID, uuid)
        XCTAssertEqual(try owners().0, uuid)
        XCTAssertEqual(try owners().1, [uuid])
    }

    func testFinalSaveFailureRollsBackLinkAndBookmarkTogether() throws {
        try seed()
        let uuid = UUID()
        model.migrateIdentity = { store, email, uuid in
            try store.activateCloudIdentity(email: email, uuid: uuid) { _ in throw InjectedFailure.save }
        }
        model.activateCloudAccount(email: email, uuid: uuid) {}
        XCTAssertFalse(model.isLoggedIn)
        XCTAssertNotNil(model.activationError)
        XCTAssertNil(try owners().0)
        XCTAssertEqual(try owners().1, [nil])
        XCTAssertNil(UserDefaults.standard.string(forKey: "LoggedInUserUUID"))

        model.migrateIdentity = { try $0.activateCloudIdentity(email: $1, uuid: $2) }
        model.retryCloudActivation()
        XCTAssertEqual(try owners().0, uuid)
        XCTAssertEqual(try owners().1, [uuid])
        XCTAssertTrue(model.isLoggedIn)
    }

    func testExistingLibraryOwnerIsNeverReassignedByEmail() throws {
        let original = UUID()
        try seed(owner: original)
        model.activateCloudAccount(email: email, uuid: UUID()) {}
        XCTAssertFalse(model.isLoggedIn)
        XCTAssertNotNil(model.activationError)
        XCTAssertEqual(try owners().0, original)
        XCTAssertEqual(try owners().1, [original])
    }

    func testIdempotentActivationAndRelaunchKeepCommittedIdentity() throws {
        try seed()
        let uuid = UUID()
        model.activateCloudAccount(email: email, uuid: uuid) {}
        model.activateCloudAccount(email: email, uuid: uuid) {}
        XCTAssertTrue(model.isLoggedIn)
        XCTAssertEqual(try owners().1, [uuid])
        let restored = UserViewModel()
        restored.setUpPersistenceController(controller: persistence)
        restored.activateCloudAccount(email: email, uuid: uuid) {}
        XCTAssertTrue(restored.isLoggedIn)
        XCTAssertEqual(restored.currentUserUUID, uuid)
        XCTAssertEqual(try owners().1, [uuid])
    }

    func testAbandonDelegatesSignOutWithoutDeletingLegacyData() throws {
        try seed()
        var signedOut = false
        model.migrateIdentity = { _, _, _ in throw InjectedFailure.link }
        model.activateCloudAccount(email: email, uuid: UUID()) { signedOut = true }
        model.abandonCloudActivation()
        XCTAssertTrue(signedOut)
        XCTAssertNil(model.activationError)
        XCTAssertEqual(try owners().1, [nil])
        model.retryCloudActivation()
        XCTAssertFalse(model.isLoggedIn)
    }

    func testEmailOnlyMigrationSkipsAlreadyOwnedBookmarks() throws {
        let original = UUID()
        try seed(owner: original)
        let context = persistence.container.viewContext
        XCTAssertEqual(try PersistenceController.migrateBookmarks(fromEmail: email, toUUID: UUID(), in: context), 0)
        XCTAssertEqual(try owners().1, [original])
    }
}
