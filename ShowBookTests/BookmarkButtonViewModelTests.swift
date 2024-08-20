//
//  BookmarkButtonViewModelTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 19/08/24.
//

import XCTest
import Combine
import CoreData
@testable import ShowBook

class BookmarkButtonViewModelTests: XCTestCase {
    var viewModel: BookmarkButtonViewModel!
    var mockPersistenceController: PersistenceController!
    var mockBook: Book!
    var mockImageUrl: URL!
    
    override func setUpWithError() throws {
            try super.setUpWithError()
        mockPersistenceController = PersistenceController.shared
        mockPersistenceController.container = PersistenceController.createInMemoryPersistentContainer()
        }
    
    override func setUp() {
        super.setUp()
//        let mockContainer = createInMemoryPersistentContainer()
//        mockPersistenceController = PersistenceController(container: mockContainer)
        viewModel = BookmarkButtonViewModel()
        mockBook = Book(title: "Test Book", ratingsAverage: 4.5, ratingsCount: 10, authorName: ["Anurag"], coverI: 12345, image: nil)
        mockImageUrl = URL(string: "https://example.com/image.jpg")!
        viewModel.configure(book: mockBook, imageUrl: mockImageUrl)
        viewModel.setUpPersitenceController(controller: mockPersistenceController)
    }
    
    override func tearDown() {
        mockPersistenceController.deleteAllBooks()
        mockPersistenceController = nil
        viewModel = nil
        mockBook = nil
        mockImageUrl = nil
        super.tearDown()
    }
    
    func testFetchInitialStateWhenBookExists() {
        mockPersistenceController.saveBook(mockBook, imageData: mockBook.image)
        viewModel.fetchInitialState()
        XCTAssertTrue(viewModel.isBookmarked)
    }
    
    func testFetchInitialStateWhenBookDoesNotExist() {
        viewModel.fetchInitialState()
        XCTAssertFalse(viewModel.isBookmarked)
    }
    
    func testToggleBookmarkWhenAdding() {
        mockPersistenceController.saveBook(mockBook, imageData: mockBook.image)
        viewModel.isBookmarked = false
        let expectation = self.expectation(description: "Handle bookmark added")
        viewModel.toggleBookmark()
        XCTAssertTrue(viewModel.isBookmarked)
        XCTAssertEqual(mockPersistenceController.fetchBooks().first?.title, mockBook.title)
        expectation.fulfill()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testToggleBookmarkWhenRemoving() {
        mockPersistenceController.saveBook(mockBook, imageData: mockBook.image)
        viewModel.isBookmarked = true
        viewModel.toggleBookmark()
        XCTAssertFalse(viewModel.isBookmarked)
        XCTAssertFalse(mockPersistenceController.fetchBooks().contains(where: { $0.title == mockBook.title}))
    }
    
    func testHandleBookmarkAddedWithoutImageUrl() {
        viewModel.imageUrl = nil
        let expectation = self.expectation(description: "Handle bookmark added")
        viewModel.handleBookmarkAdded {
            let fetchedBook = self.mockPersistenceController.fetchBooks().first
            XCTAssertEqual(fetchedBook?.title, self.mockBook.title)
            XCTAssertFalse(self.mockPersistenceController.doesBookHaveImageData(title: self.mockBook.title, authors: self.mockBook.authorName))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testHandleBookmarkAddedWithImageUrl() {
        let imageData = Data()
        mockPersistenceController.saveBook(mockBook, imageData: imageData)
        let expectation = self.expectation(description: "Handle bookmark added with image")
        viewModel.handleBookmarkAdded {
            let fetchedBook = self.mockPersistenceController.fetchBooks().first
            XCTAssertEqual(fetchedBook?.title, self.mockBook.title)
            XCTAssertNotEqual(fetchedBook?.image, imageData)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
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
