//
//  UserViewModelTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
import UIKit
import SwiftUI
import DesignTokensKit
@testable import ShowBook
import CoreData

final class UserViewModelTests: XCTestCase {
    var viewModel: UserViewModel!
    var mockPersistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockPersistenceController = PersistenceController.inMemory()
    }
    
    override func setUp() {
        super.setUp()
        viewModel = UserViewModel(persistenceController: mockPersistenceController)
    }
    
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        viewModel = nil
        mockPersistenceController = nil
    }
    
    func testCheck_LoginStatusWhenUserIsLoggedIn() {
        // Given
        let uuid = UUID()
        UserDefaults.standard.set(uuid.uuidString, forKey: "LoggedInUserUUID")
        
        self.viewModel.checkLoginStatus()

        XCTAssertTrue(self.viewModel.isLoggedIn, "User should be logged in when a valid UUID is found in UserDefaults.")
    }
    
    func testCheck_LoginStatusWhenUserIsNotLoggedIn() {
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        self.viewModel.checkLoginStatus()
        XCTAssertFalse(self.viewModel.isLoggedIn, "User should not be logged in when no UUID is found in UserDefaults.")
    }
    
    func testCheck_LoginStatusWhenNoEmailInUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        self.viewModel.checkLoginStatus()
        XCTAssertFalse(self.viewModel.isLoggedIn, "User should not be logged in when no UUID is found in UserDefaults.")
    }
    
    func testCheck_Logout() {
        let uuid = UUID()
        UserDefaults.standard.set(uuid.uuidString, forKey: "LoggedInUserUUID")
        self.viewModel.checkLoginStatus()
        self.viewModel.logout()
        XCTAssertNil(UserDefaults.standard.value(forKey: "LoggedInUserUUID"), "LoggedInUserUUID should be removed from UserDefaults after logout.")
        XCTAssertFalse(self.viewModel.isLoggedIn, "User should be logged out.")
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
        let palette = BrandPalette.showBook
        let colors: [Color] = [
            palette.background, palette.surface, palette.action,
            palette.authBackground, palette.authForeground, palette.authAction, palette.authOnAction
        ]
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for color in colors {
                let resolved = UIColor(color).resolvedColor(with: traits)
                XCTAssertEqual(resolved.cgColor.alpha, 1, accuracy: 0.001,
                               "Brand color must remain opaque")
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

    func testSupabaseConfigurationIsResolvedFromBuildConfiguration() {
        let bundle = Bundle.main
        if let supabaseURL = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String {
            XCTAssertFalse(supabaseURL.contains("$("), "SUPABASE_URL must be resolved by xcconfig, not raw macro string")
            XCTAssertTrue(supabaseURL.starts(with: "https://"), "Resolved SUPABASE_URL must be a valid https URL")
        }
        if let key = bundle.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String {
            XCTAssertFalse(key.contains("$("), "SUPABASE_PUBLISHABLE_KEY must be resolved by xcconfig, not raw macro string")
        }
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
        persistence = PersistenceController.inMemory()
        model = UserViewModel(persistenceController: persistence)
    }

    override func tearDownWithError() throws {
        model = nil
        persistence = nil
        UserDefaults.standard.set(previousEmail, forKey: "LoggedInUserEmail")
        UserDefaults.standard.set(previousUUID, forKey: "LoggedInUserUUID")
    }

    private func seed(owner: UUID? = nil) throws {
        let context = persistence.container.viewContext
        let book = try XCTUnwrap(NSEntityDescription.insertNewObject(forEntityName: "BookEntity", into: context) as? BookEntity)
        book.title = "Preserved legacy book"
        book.email = email
        book.userUUID = owner
        book.ownerID = owner?.uuidString.lowercased()
        try context.save()
    }

    private func owners() throws -> [UUID?] {
        let context = persistence.container.newBackgroundContext()
        return try context.performAndWait {
            let books = try context.fetch(BookEntity.fetchRequest())
            return books.map(\.userUUID)
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
        XCTAssertEqual(try owners(), [nil])
        model.checkLoginStatus()
        XCTAssertFalse(model.isLoggedIn)

        model.retryCloudActivation()
        XCTAssertTrue(model.isLoggedIn)
        XCTAssertNil(model.activationError)
        XCTAssertEqual(model.currentUserUUID, uuid)
        XCTAssertEqual(try owners(), [uuid])
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
        XCTAssertEqual(try owners(), [nil])
        XCTAssertNil(UserDefaults.standard.string(forKey: "LoggedInUserUUID"))

        model.migrateIdentity = { try $0.activateCloudIdentity(email: $1, uuid: $2) }
        model.retryCloudActivation()
        XCTAssertEqual(try owners(), [uuid])
        XCTAssertTrue(model.isLoggedIn)
    }

    func testExistingLibraryOwnerIsNeverReassignedByEmail() throws {
        let original = UUID()
        try seed(owner: original)
        model.activateCloudAccount(email: email, uuid: UUID()) {}
        XCTAssertFalse(model.isLoggedIn)
        XCTAssertNotNil(model.activationError)
        XCTAssertEqual(try owners(), [original])
    }

    func testIdempotentActivationAndRelaunchKeepCommittedIdentity() throws {
        try seed()
        let uuid = UUID()
        model.activateCloudAccount(email: email, uuid: uuid) {}
        model.activateCloudAccount(email: email, uuid: uuid) {}
        XCTAssertTrue(model.isLoggedIn)
        XCTAssertEqual(try owners(), [uuid])
        let restored = UserViewModel(persistenceController: persistence)
        restored.activateCloudAccount(email: email, uuid: uuid) {}
        XCTAssertTrue(restored.isLoggedIn)
        XCTAssertEqual(restored.currentUserUUID, uuid)
        XCTAssertEqual(try owners(), [uuid])
    }

    func testAbandonDelegatesSignOutWithoutDeletingLegacyData() throws {
        try seed()
        var signedOut = false
        model.migrateIdentity = { _, _, _ in throw InjectedFailure.link }
        model.activateCloudAccount(email: email, uuid: UUID()) { signedOut = true }
        model.abandonCloudActivation()
        XCTAssertTrue(signedOut)
        XCTAssertNil(model.activationError)
        XCTAssertEqual(try owners(), [nil])
        model.retryCloudActivation()
        XCTAssertFalse(model.isLoggedIn)
    }

    func testEmailOnlyMigrationSkipsAlreadyOwnedBookmarks() throws {
        let original = UUID()
        try seed(owner: original)
        let context = persistence.container.viewContext
        XCTAssertEqual(try PersistenceController.migrateBookmarks(fromEmail: email, toUUID: UUID(), in: context), 0)
        XCTAssertEqual(try owners(), [original])
    }
}
