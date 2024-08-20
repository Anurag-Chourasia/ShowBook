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
