//
//  BookmarkViewModelTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 19/08/24.
//

import XCTest
import Combine
import CoreData
@testable import ShowBook

class BookmarkViewModelTests: XCTestCase {
    var viewModel: BookmarkViewModel!
    var mockPersistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockPersistenceController = PersistenceController.inMemory()
    }
    
    override func setUp() {
        super.setUp()
        mockPersistenceController.deleteAllBooks()
        viewModel = BookmarkViewModel(persistenceController: mockPersistenceController)
    }
    
    func testLoadBookmarksSuccess() {
        // Arrange
        let books = [Book(title: "Test Book", ratingsAverage: 4.5, ratingsCount: 10, authorName: ["Anurag"], coverI: 1234, image: nil)]
        for book in books {
            mockPersistenceController.saveBook(book, imageData: book.image)
        }
        
        viewModel.loadBookmarks()
        
        XCTAssertEqual(viewModel.bookmarkBooks.count, books.count)
        XCTAssertEqual(viewModel.bookmarkBooks.first?.title, books.first?.title)
        XCTAssertEqual(viewModel.bookmarkBooks.first?.authorName, books.first?.authorName)
        XCTAssertFalse(viewModel.showAlert)
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

/// Exercises the versioned persistence schema without touching the user's store.
final class PersistenceRelationshipTests: XCTestCase {
    private func model(version: String? = nil) throws -> NSManagedObjectModel {
        let directory = try XCTUnwrap(Bundle.main.url(forResource: "ShowBook", withExtension: "momd"))
        let url = version.map { directory.appendingPathComponent($0 + ".mom") } ?? directory
        let loaded = try XCTUnwrap(NSManagedObjectModel(contentsOf: url))
        let model = try XCTUnwrap(loaded.copy() as? NSManagedObjectModel)
        // Generic objects keep the fixture independent of generated subclass accessors.
        for entity in model.entities { entity.managedObjectClassName = "NSManagedObject" }
        return model
    }

    func testCurrentModelInversesAndNullifyBehavior() throws {
        let model = try model()
        for entity in model.entities {
            for relationship in entity.relationshipsByName.values {
                let inverse = try XCTUnwrap(relationship.inverseRelationship)
                XCTAssertTrue(inverse.inverseRelationship === relationship)
            }
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        _ = try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let catalog = NSEntityDescription.insertNewObject(forEntityName: "CountryEntity", into: context)
        let datum = NSEntityDescription.insertNewObject(forEntityName: "DatumEntity", into: context)
        let region = NSEntityDescription.insertNewObject(forEntityName: "RegionEntity", into: context)
        catalog.mutableSetValue(forKey: "data").add(datum)
        datum.setValue(region, forKey: "region")
        XCTAssertTrue(datum.value(forKey: "catalog") as? NSManagedObject === catalog)
        XCTAssertTrue((region.value(forKey: "data") as? NSSet)?.contains(datum) == true)
        try context.save()
        context.delete(catalog)
        context.delete(region)
        try context.save()
        XCTAssertFalse(datum.isDeleted)
        XCTAssertNil(datum.value(forKey: "catalog"))
        XCTAssertNil(datum.value(forKey: "region"))
    }

    func testLegacySQLiteStoreMigratesWithoutLosingData() throws {
        for version in ["ShowBook", "ShowBookV2", "ShowBookV3", "ShowBookV4"] {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("fixture.sqlite")
        let legacy = try model(version: version)
        let oldCoordinator = NSPersistentStoreCoordinator(managedObjectModel: legacy)
        let oldStore = try oldCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        let oldContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        oldContext.persistentStoreCoordinator = oldCoordinator
        let catalog = NSEntityDescription.insertNewObject(forEntityName: "CountryEntity", into: oldContext)
        catalog.setValue("India", forKey: "selectedCountryName")
        let region = NSEntityDescription.insertNewObject(forEntityName: "RegionEntity", into: oldContext)
        region.setValue("Asia", forKey: "region")
        for country in ["India", "Nepal"] {
            let datum = NSEntityDescription.insertNewObject(forEntityName: "DatumEntity", into: oldContext)
            datum.setValue(country, forKey: "country")
            datum.setValue(region, forKey: "region")
            catalog.mutableSetValue(forKey: "data").add(datum)
        }
        let book = NSEntityDescription.insertNewObject(forEntityName: "BookEntity", into: oldContext)
        book.setValue("Saved bookmark", forKey: "title")
        try oldContext.save()
        oldContext.reset()
        try oldCoordinator.remove(oldStore)

        let current = try model()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: current)
        let store = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL,
            options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        defer { try? coordinator.remove(store) }
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let catalogs = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "CountryEntity"))
        XCTAssertEqual(catalogs.count, 1)
        let migratedCatalog = try XCTUnwrap(catalogs.first)
        XCTAssertEqual(migratedCatalog.value(forKey: "selectedCountryName") as? String, "India")
        let data = try XCTUnwrap(migratedCatalog.value(forKey: "data") as? Set<NSManagedObject>)
        XCTAssertEqual(Set(data.compactMap { $0.value(forKey: "country") as? String }), ["India", "Nepal"])
        for datum in data {
            XCTAssertTrue(datum.value(forKey: "catalog") as? NSManagedObject === migratedCatalog)
            let migratedRegion = try XCTUnwrap(datum.value(forKey: "region") as? NSManagedObject)
            XCTAssertEqual(migratedRegion.value(forKey: "region") as? String, "Asia")
            XCTAssertEqual((migratedRegion.value(forKey: "data") as? NSSet)?.count, 2)
        }
        let books = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "BookEntity"))
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?.value(forKey: "title") as? String, "Saved bookmark")
        XCTAssertNil(books.first?.value(forKey: "workKey"))
        XCTAssertNil(books.first?.value(forKey: "userUUID"))
        }
    }
}

final class BookmarkUUIDMigrationTests: XCTestCase {
    var persistence: PersistenceController!
    var userViewModel: UserViewModel!
    var bookmarkViewModel: BookmarkViewModel!

    @discardableResult
    private func createBookEntity(
        in context: NSManagedObjectContext,
        title: String,
        email: String,
        userUUID: UUID? = nil
    ) -> BookEntity {
        guard let entity = NSEntityDescription.insertNewObject(forEntityName: "BookEntity", into: context) as? BookEntity else {
            fatalError("Failed to cast to BookEntity")
        }
        entity.title = title
        entity.email = email
        entity.userUUID = userUUID
        return entity
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        UserDefaults.standard.removeObject(forKey: "developer.authentication")

        persistence = PersistenceController.inMemory()
        userViewModel = UserViewModel(persistenceController: persistence)
        bookmarkViewModel = BookmarkViewModel(persistenceController: persistence)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        UserDefaults.standard.removeObject(forKey: "developer.authentication")
        persistence = nil
        userViewModel = nil
        bookmarkViewModel = nil
        super.tearDown()
    }

    func testModelV7DropsUserEntity() throws {
        let model = PersistenceController.managedObjectModel()
        XCTAssertNil(model.entitiesByName["UserEntity"], "UserEntity must be removed from Core Data model V7")
        XCTAssertNotNil(model.entitiesByName["BookEntity"])
        XCTAssertNotNil(model.entitiesByName["CountryEntity"])
        XCTAssertNotNil(model.entitiesByName["DatumEntity"])
        XCTAssertNotNil(model.entitiesByName["RegionEntity"])
        XCTAssertNotNil(model.entitiesByName["UserPreference"])
    }

    func testEmailToUUIDBookmarkMigration() throws {
        let email = "reader@example.com"
        let targetUUID = UUID()
        let context = persistence.container.viewContext

        for i in 1...3 {
            createBookEntity(in: context, title: "Book \(i)", email: email, userUUID: nil)
        }
        try context.save()

        let migratedCount = try PersistenceController.migrateBookmarks(fromEmail: email, toUUID: targetUUID, in: context)
        XCTAssertEqual(migratedCount, 3)

        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let books = try context.fetch(request)
        XCTAssertEqual(books.count, 3)
        for book in books {
            XCTAssertEqual(book.userUUID, targetUUID)
            XCTAssertEqual(book.email, email)
        }

        let secondRun = try PersistenceController.migrateBookmarks(fromEmail: email, toUUID: targetUUID, in: context)
        XCTAssertEqual(secondRun, 0)
    }

    func testEmailChangePreservesBookmarksAcrossCloudSessions() throws {
        let stableUUID = UUID()
        let initialEmail = "reader.initial@example.com"
        let updatedEmail = "reader.updated@example.com"

        userViewModel.activateCloudAccount(email: initialEmail, uuid: stableUUID) {}
        XCTAssertEqual(userViewModel.currentUserUUID, stableUUID)

        let book = Book(title: "Architecture Patterns", ratingsAverage: 4.8, ratingsCount: 15, authorName: ["Author"], coverI: 101, image: nil)
        persistence.saveBook(book, imageData: nil)

        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 1)
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.first?.title, "Architecture Patterns")

        userViewModel.activateCloudAccount(email: updatedEmail, uuid: stableUUID) {}
        XCTAssertEqual(userViewModel.currentUserUUID, stableUUID)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "LoggedInUserEmail"), updatedEmail)

        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 1)
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.first?.title, "Architecture Patterns")
    }

    func testAccountSwitchingIsolatesBookmarks() throws {
        let userAUUID = UUID()
        let userAEmail = "userA@example.com"
        let userBUUID = UUID()
        let userBEmail = "userB@example.com"

        userViewModel.activateCloudAccount(email: userAEmail, uuid: userAUUID) {}
        let bookA = Book(title: "Book of A", ratingsAverage: 4.0, ratingsCount: 1, authorName: ["Author A"], coverI: 1, image: nil)
        persistence.saveBook(bookA, imageData: nil)

        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.map(\.title), ["Book of A"])

        userViewModel.activateCloudAccount(email: userBEmail, uuid: userBUUID) {}
        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 0)

        let bookB = Book(title: "Book of B", ratingsAverage: 5.0, ratingsCount: 2, authorName: ["Author B"], coverI: 2, image: nil)
        persistence.saveBook(bookB, imageData: nil)

        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.map(\.title), ["Book of B"])

        userViewModel.activateCloudAccount(email: userAEmail, uuid: userAUUID) {}
        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.map(\.title), ["Book of A"])

        userViewModel.clearCloudAccount()
        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 0)
    }

    func testV7ModelPreservesBookmarksAndPreferences() throws {
        let email = "hybrid@example.com"
        let cloudUUID = UUID()
        userViewModel.activateCloudAccount(email: email, uuid: cloudUUID) {}

        let book = Book(title: "Local Story", ratingsAverage: 4.2, ratingsCount: 3, authorName: ["Local Author"], coverI: 50, image: nil)
        persistence.saveBook(book, imageData: nil)
        XCTAssertTrue(persistence.doesBookExist(title: "Local Story", authors: ["Local Author"]))

        let migratedBooks = persistence.fetchBooks()
        XCTAssertEqual(migratedBooks.count, 1)
        XCTAssertEqual(migratedBooks.first?.title, "Local Story")
    }

    func testFailedMigrationRollbackPreservesOriginalRecords() throws {
        let email = "failing@example.com"
        let targetUUID = UUID()
        let context = persistence.container.viewContext

        createBookEntity(in: context, title: "Unmigrated Book", email: email, userUUID: nil)
        try context.save()

        struct SimulatedSaveError: Error {}

        XCTAssertThrowsError(
            try PersistenceController.migrateBookmarks(
                fromEmail: email,
                toUUID: targetUUID,
                in: context,
                save: { _ in throw SimulatedSaveError() }
            )
        )

        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", "Unmigrated Book")
        let books = try context.fetch(request)
        XCTAssertEqual(books.count, 1)
        XCTAssertNil(books.first?.userUUID, "Failed migration must roll back userUUID mutation")
        XCTAssertEqual(books.first?.email, email)
    }

    func testExplicitRollbackBookmarkMigration() throws {
        let email = "rollback@example.com"
        let uuid = UUID()
        let context = persistence.container.viewContext

        createBookEntity(in: context, title: "Rollback Candidate", email: email, userUUID: uuid)
        try context.save()

        let rolledBackCount = try PersistenceController.rollbackBookmarkMigration(forUUID: uuid, in: context)
        XCTAssertEqual(rolledBackCount, 1)

        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", "Rollback Candidate")
        let books = try context.fetch(request)
        XCTAssertEqual(books.count, 1)
        XCTAssertNil(books.first?.userUUID)
        XCTAssertEqual(books.first?.email, email)
    }

    func testRecoverableStoreLoadFailurePreservesDataWithoutDeletion() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let storeURL = tempDirectory.appendingPathComponent("ShowBookTest.sqlite")
        let model = PersistenceController.managedObjectModel()

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        createBookEntity(in: context, title: "Durable Book", email: "durable@example.com")
        try context.save()
        try coordinator.remove(store)

        struct SimulatedLoadError: Error {}
        let controller = PersistenceController(container: NSPersistentContainer(name: "ShowBook", managedObjectModel: model))

        #if DEBUG
        controller.simulateStoreLoadFailure(error: SimulatedLoadError())
        XCTAssertFalse(controller.isStoreLoaded)
        XCTAssertNotNil(controller.storeLoadError)

        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path), "Store files must be preserved without automatic deletion")

        controller.clearStoreLoadFailure()
        XCTAssertTrue(controller.isStoreLoaded)
        XCTAssertNil(controller.storeLoadError)
        #endif
    }

    func testModelV6ContainsUserPreferenceAndBookmarkOwnerID() throws {
        let model = PersistenceController.managedObjectModel()
        guard let bookEntity = model.entitiesByName["BookEntity"] else {
            XCTFail("BookEntity not found in model")
            return
        }
        XCTAssertNotNil(bookEntity.attributesByName["ownerID"], "BookEntity must contain ownerID attribute in V6")

        guard let userPreferenceEntity = model.entitiesByName["UserPreference"] else {
            XCTFail("UserPreference entity not found in model V6")
            return
        }
        XCTAssertNotNil(userPreferenceEntity.attributesByName["ownerID"])
        XCTAssertNotNil(userPreferenceEntity.attributesByName["selectedCountryName"])
        XCTAssertNotNil(userPreferenceEntity.attributesByName["userUUID"])
    }

    func testUserPreferenceSavesAndFetchesCountry() throws {
        let testCountry = "Germany"
        persistence.saveDefaultCountryName(selectedCountryName: testCountry)
        XCTAssertEqual(persistence.fetchSelectedCountryName(), testCountry)

        // Verify UserPreference managed object
        let context = persistence.container.viewContext
        let request: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
        let prefs = try context.fetch(request)
        XCTAssertFalse(prefs.isEmpty)
        XCTAssertEqual(prefs.first?.selectedCountryName, testCountry)
    }

    func testBookmarkOwnerIDSavedAndMigrated() throws {
        let email = "v6owner@example.com"
        let uuid = UUID()
        let context = persistence.container.viewContext

        createBookEntity(in: context, title: "V6 Book", email: email, userUUID: nil)
        try context.save()

        let migrated = try PersistenceController.migrateBookmarks(fromEmail: email, toUUID: uuid, in: context)
        XCTAssertEqual(migrated, 1)

        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", "V6 Book")
        let book = try context.fetch(request).first
        XCTAssertNotNil(book)
        XCTAssertEqual(book?.userUUID, uuid)
        XCTAssertEqual(book?.ownerID, uuid.uuidString.lowercased())

        let rolledBack = try PersistenceController.rollbackBookmarkMigration(forUUID: uuid, in: context)
        XCTAssertEqual(rolledBack, 1)
        XCTAssertNil(book?.userUUID)
        XCTAssertNil(book?.ownerID)
    }

    func testFirstSignInRekeysAnonymousBookmarksToAuthKitUser() throws {
        let authUUID = UUID()
        let authEmail = "newauth@example.com"
        let context = persistence.container.viewContext

        createBookEntity(in: context, title: "Anon Book 1", email: "", userUUID: nil)
        createBookEntity(in: context, title: "Anon Book 2", email: "", userUUID: nil)
        try context.save()

        userViewModel.activateCloudAccount(email: authEmail, uuid: authUUID) {}
        XCTAssertEqual(userViewModel.currentUserUUID, authUUID)

        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let books = try context.fetch(request)
        XCTAssertEqual(books.count, 2)
        for book in books {
            XCTAssertEqual(book.userUUID, authUUID)
            XCTAssertEqual(book.ownerID, authUUID.uuidString.lowercased())
            XCTAssertEqual(book.email, authEmail)
        }

        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 2)
    }

    func testFirstSignInRekeyViaRepository() throws {
        let repo = BookmarkRepositoryImpl(persistenceController: persistence)
        let authUUID = UUID()
        let email = "rekeyrepo@example.com"
        let context = persistence.container.viewContext

        createBookEntity(in: context, title: "Repo Rekey Book", email: email, userUUID: nil)
        try context.save()

        let count = try repo.rekeyBookmarks(fromEmail: email, toUUID: authUUID)
        XCTAssertEqual(count, 1)

        let idempotentCount = try repo.rekeyBookmarks(fromEmail: email, toUUID: authUUID)
        XCTAssertEqual(idempotentCount, 0)

        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", "Repo Rekey Book")
        let book = try context.fetch(request).first
        XCTAssertEqual(book?.userUUID, authUUID)
        XCTAssertEqual(book?.ownerID, authUUID.uuidString.lowercased())
    }

    func testFirstSignInRekeyPreservesIsolationBetweenDifferentAccounts() throws {
        let userAUUID = UUID()
        let userAEmail = "userA.isolated@example.com"
        let userBUUID = UUID()
        let userBEmail = "userB.isolated@example.com"
        let context = persistence.container.viewContext

        let bookA = createBookEntity(in: context, title: "User A Book", email: userAEmail, userUUID: userAUUID)
        bookA.ownerID = userAUUID.uuidString.lowercased()

        createBookEntity(in: context, title: "Unowned Local Book", email: "", userUUID: nil)
        try context.save()

        userViewModel.activateCloudAccount(email: userBEmail, uuid: userBUUID) {}
        XCTAssertEqual(userViewModel.currentUserUUID, userBUUID)

        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 1)
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.first?.title, "Unowned Local Book")

        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", "User A Book")
        let fetchedBookA = try context.fetch(request).first
        XCTAssertEqual(fetchedBookA?.userUUID, userAUUID)
        XCTAssertEqual(fetchedBookA?.ownerID, userAUUID.uuidString.lowercased())
    }
}
