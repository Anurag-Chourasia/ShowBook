//
//  LoginViewTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
@testable import ShowBook
import CoreData
import Combine

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
    
    private func waitForLogin() {
        let finished = expectation(description: "login finished")
        var started = false
        let subscription = loginViewModel.$isLoading.sink { loading in
            if loading { started = true }
            else if started { DispatchQueue.main.async { finished.fulfill() } }
        }
        loginViewModel.handleLogin(userViewModel: userViewModel)
        wait(for: [finished], timeout: 10)
        withExtendedLifetime(subscription) {}
    }

    func testValidLogin() {
        if mockPersistenceController.saveUser(email: "test@example.com", password: "ValidPassword123@"){
            
            loginViewModel.email = "test@example.com"
            loginViewModel.password = "ValidPassword123@"
            waitForLogin()
            
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
            waitForLogin()
            
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


final class CredentialStorageTests: XCTestCase {
    private let password = "ValidPassword123@"
    private func controller() -> PersistenceController {
        PersistenceController(container: PersistenceController.createInMemoryPersistentContainer())
    }
    private func legacyUser(_ controller: PersistenceController) throws -> UserEntity {
        let context = controller.container.viewContext
        let user = UserEntity(entity: NSEntityDescription.entity(forEntityName: "UserEntity", in: context)!, insertInto: context)
        user.email = "legacy@example.com"
        user.password = password
        user.isSuccessfullyLoggedIn = false
        try controller.container.viewContext.save()
        return user
    }
    private func completed(_ operation: (@escaping (Result<Void, Error>) -> Void) -> Void) -> Result<Void, Error> {
        let done = expectation(description: "credential operation completes")
        var outcome: Result<Void, Error>!
        operation {
            XCTAssertTrue(Thread.isMainThread)
            outcome = $0
            done.fulfill()
        }
        wait(for: [done], timeout: 15)
        return outcome
    }

    func testHashMatchesIndependentPBKDF2VectorAndHandlesUnicodeAndNUL() throws {
        // Python hashlib.pbkdf2_hmac SHA-256, 600000 rounds, salt bytes 0...15, 32-byte key.
        let vector = "pbkdf2-sha256$1$600000$AAECAwQFBgcICQoLDA0ODw==$AEqt/LKttoSPSd3R+MVI8WRJklE1sGsog9jAVlSCifY="
        XCTAssertTrue(try PasswordCredential.verify("päss🔒word\0tail", encoded: vector))
        XCTAssertFalse(try PasswordCredential.verify("päss🔒word", encoded: vector))
    }

    func testRandomSaltsWrongPasswordAndMalformedRecords() throws {
        let first = try PasswordCredential.make(password)
        let second = try PasswordCredential.make(password)
        XCTAssertNotEqual(first, second)
        XCTAssertTrue(try PasswordCredential.verify(password, encoded: first))
        XCTAssertFalse(try PasswordCredential.verify("WrongPassword123@", encoded: first))
        XCTAssertFalse(try PasswordCredential.verify(first, encoded: first))
        for invalid in ["", password, first.replacingOccurrences(of: "$600000$", with: "$999999999$"), "pbkdf2-sha256$1$600000$bad$bad"] {
            XCTAssertThrowsError(try PasswordCredential.verify(password, encoded: invalid))
        }
    }

    func testRegistrationStoresOnlyHashAndRejectsDuplicate() throws {
        let store = controller()
        try completed { store.registerUser(email: "NEW@example.com", password: password, completion: $0) }.get()
        let user = try XCTUnwrap(store.fetchUser(email: "new@example.com"))
        XCTAssertNil(user.password)
        let hash = try XCTUnwrap(user.passwordHash)
        XCTAssertTrue(try PasswordCredential.verify(password, encoded: hash))
        XCTAssertThrowsError(try completed { store.registerUser(email: "new@example.com", password: "OtherPassword123@", completion: $0) }.get())
        XCTAssertEqual(user.passwordHash, hash)
        try completed { store.authenticate(email: "new@example.com", password: password, completion: $0) }.get()
        XCTAssertThrowsError(try completed { store.authenticate(email: "new@example.com", password: "WrongPassword123@", completion: $0) }.get())
    }

    func testLegacyLoginMigratesOnlyAfterCorrectPassword() throws {
        let store = controller()
        let user = try legacyUser(store)
        XCTAssertThrowsError(try completed { store.authenticate(email: "legacy@example.com", password: "WrongPassword123@", completion: $0) }.get())
        store.container.viewContext.refresh(user, mergeChanges: false)
        XCTAssertEqual(user.password, password)
        XCTAssertNil(user.passwordHash)
        XCTAssertFalse(user.isSuccessfullyLoggedIn)
        try completed { store.authenticate(email: "legacy@example.com", password: password, completion: $0) }.get()
        store.container.viewContext.refresh(user, mergeChanges: false)
        XCTAssertNil(user.password)
        XCTAssertTrue(try PasswordCredential.verify(password, encoded: XCTUnwrap(user.passwordHash)))
        XCTAssertTrue(user.isSuccessfullyLoggedIn)
    }

    func testMigrationIsIdempotentAndPreservesLoggedOutState() throws {
        let store = controller()
        let user = try legacyUser(store)
        try completed { store.migrateLegacyCredentials(completion: $0) }.get()
        store.container.viewContext.refresh(user, mergeChanges: false)
        let hash = try XCTUnwrap(user.passwordHash)
        XCTAssertNil(user.password)
        XCTAssertFalse(user.isSuccessfullyLoggedIn)
        try completed { store.migrateLegacyCredentials(completion: $0) }.get()
        store.container.viewContext.refresh(user, mergeChanges: false)
        XCTAssertEqual(user.passwordHash, hash)
    }

    func testHashingAndSaveFailuresPreserveLegacyCredentialForRetry() throws {
        let store = controller()
        let user = try legacyUser(store)
        let context = store.container.viewContext
        let failure = NSError(domain: "InjectedFailure", code: 1)
        XCTAssertThrowsError(try PersistenceController.migrateLegacyCredentials(in: context, hashPassword: { _ in throw failure }))
        XCTAssertEqual(user.password, password)
        XCTAssertNil(user.passwordHash)
        XCTAssertThrowsError(try PersistenceController.migrateLegacyCredentials(in: context, save: { _ in throw failure }))
        XCTAssertEqual(user.password, password)
        XCTAssertNil(user.passwordHash)
        XCTAssertFalse(user.isSuccessfullyLoggedIn)
        try PersistenceController.migrateLegacyCredentials(in: context)
        XCTAssertNil(user.password)
        XCTAssertNotNil(user.passwordHash)
    }

    func testCorruptHashDoesNotFallBackToPlaintext() throws {
        let store = controller()
        let user = try legacyUser(store)
        user.passwordHash = "corrupt"
        try store.container.viewContext.save()
        XCTAssertThrowsError(try completed { store.authenticate(email: "legacy@example.com", password: password, completion: $0) }.get())
        XCTAssertThrowsError(try completed { store.migrateLegacyCredentials(completion: $0) }.get())
        store.container.viewContext.refresh(user, mergeChanges: false)
        XCTAssertEqual(user.password, password)
        XCTAssertFalse(user.isSuccessfullyLoggedIn)
    }

    func testOneCorruptAccountDoesNotBlockOtherMigrations() throws {
        let store = controller()
        let bad = try legacyUser(store)
        bad.passwordHash = "corrupt"
        let context = store.container.viewContext
        let good = UserEntity(entity: NSEntityDescription.entity(forEntityName: "UserEntity", in: context)!, insertInto: context)
        good.email = "other@example.com"
        good.password = password
        try context.save()
        XCTAssertThrowsError(try PersistenceController.migrateLegacyCredentials(in: context))
        XCTAssertEqual(bad.password, password)
        XCTAssertNil(good.password)
        XCTAssertTrue(try PasswordCredential.verify(password, encoded: XCTUnwrap(good.passwordHash)))
    }

    func testReadOnlyStoreDoesNotGrantLoginOrCreateAccountOnSaveFailure() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("readonly.sqlite")
        func open(readOnly: Bool) throws -> NSPersistentContainer {
            let container = NSPersistentContainer(name: "ShowBook", managedObjectModel: PersistenceController.managedObjectModel())
            let description = NSPersistentStoreDescription(url: url)
            description.setOption(NSNumber(value: readOnly), forKey: NSReadOnlyPersistentStoreOption)
            container.persistentStoreDescriptions = [description]
            var failure: Error?
            container.loadPersistentStores { _, error in failure = error }
            if let failure { throw failure }
            return container
        }
        let writable = try open(readOnly: false)
        _ = try legacyUser(PersistenceController(container: writable))
        writable.viewContext.reset()
        for store in writable.persistentStoreCoordinator.persistentStores { try writable.persistentStoreCoordinator.remove(store) }
        let readOnly = try open(readOnly: true)
        let store = PersistenceController(container: readOnly)
        XCTAssertThrowsError(try completed { store.authenticate(email: "legacy@example.com", password: password, completion: $0) }.get())
        let legacy = try XCTUnwrap(store.fetchUser(email: "legacy@example.com"))
        XCTAssertFalse(legacy.isSuccessfullyLoggedIn)
        XCTAssertEqual(legacy.password, password)
        XCTAssertNil(legacy.passwordHash)
        XCTAssertThrowsError(try completed { store.registerUser(email: "new@example.com", password: password, completion: $0) }.get())
        XCTAssertNil(store.fetchUser(email: "new@example.com"))
        readOnly.viewContext.reset()
        for persistentStore in readOnly.persistentStoreCoordinator.persistentStores { try readOnly.persistentStoreCoordinator.remove(persistentStore) }
    }

    func testV1AndV2SQLiteStoresUpgradeAndRetainAccounts() throws {
        for version in ["ShowBook", "ShowBookV2"] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("credentials.sqlite")
            let momd = try XCTUnwrap(Bundle.main.url(forResource: "ShowBook", withExtension: "momd"))
            let oldModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("\(version).mom"))?.copy() as? NSManagedObjectModel)
            for entity in oldModel.entities { entity.managedObjectClassName = "NSManagedObject" }
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: oldModel)
            let oldStore = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url)
            let oldContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            oldContext.persistentStoreCoordinator = coordinator
            let legacy = NSEntityDescription.insertNewObject(forEntityName: "UserEntity", into: oldContext)
            legacy.setValue("legacy@example.com", forKey: "email")
            // Hash-like legacy passwords must not be mistaken for new credential records.
            let legacyPassword = "pbkdf2-sha256$1$600000$LegacyPassword123@"
            legacy.setValue(legacyPassword, forKey: "password")
            legacy.setValue(true, forKey: "isSuccessfullyLoggedIn")
            try oldContext.save()
            oldContext.reset()
            try coordinator.remove(oldStore)

            let container = NSPersistentContainer(name: "ShowBook", managedObjectModel: PersistenceController.managedObjectModel())
            let description = NSPersistentStoreDescription(url: url)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]
            var loadingError: Error?
            container.loadPersistentStores { _, error in loadingError = error }
            XCTAssertNil(loadingError)
            let store = PersistenceController(container: container)
            try completed { store.migrateLegacyCredentials(completion: $0) }.get()
            let migrated = try XCTUnwrap(store.fetchUser(email: "legacy@example.com"))
            XCTAssertNil(migrated.password)
            XCTAssertTrue(migrated.isSuccessfullyLoggedIn)
            XCTAssertTrue(try PasswordCredential.verify(legacyPassword, encoded: XCTUnwrap(migrated.passwordHash)))
            try completed { store.authenticate(email: "legacy@example.com", password: legacyPassword, completion: $0) }.get()
            container.viewContext.reset()
            for persistentStore in container.persistentStoreCoordinator.persistentStores {
                try container.persistentStoreCoordinator.remove(persistentStore)
            }
        }
    }
}
