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
        mockPersistenceController = PersistenceController.shared
        mockPersistenceController.container = PersistenceController.createInMemoryPersistentContainer()
        }
    
    override func setUp() {
        super.setUp()
//        let mockContainer = createInMemoryPersistentContainer()
//        mockPersistenceController = PersistenceController(container: mockContainer)
        mockPersistenceController.deleteAllBooks()
        viewModel = BookmarkViewModel()
        viewModel.setUpPersitenceController(controller: mockPersistenceController)
        
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
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("fixture.sqlite")
        let legacy = try model(version: "ShowBook")
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
    }
}
