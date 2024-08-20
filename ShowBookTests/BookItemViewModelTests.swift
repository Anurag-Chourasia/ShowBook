//
//  BookItemViewModelTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
import Combine
import CoreData
@testable import ShowBook

class BookItemViewModelTests: XCTestCase {
    var viewModel: BookItemViewModel!
    var mockPersistenceController: PersistenceController!
    var mockBook: Book!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockPersistenceController = PersistenceController.shared
        mockPersistenceController.container = PersistenceController.createInMemoryPersistentContainer()
    }
    
    
    override func setUp() {
        super.setUp()
        mockBook = Book(title: "Test Book", ratingsAverage: 4.5, ratingsCount: 100, authorName: ["Anurag"], coverI: 12345, image: nil)
        //        let mockContainer = createInMemoryPersistentContainer()
        //        mockPersistenceController = PersistenceController(container: mockContainer)
        viewModel = BookItemViewModel(item: mockBook)
        viewModel.setUpPersistenceController(controller: mockPersistenceController)
    }
    
    override func tearDown() {
        viewModel = nil
        mockPersistenceController = nil
        mockBook = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testInitialState() {
        let expectedAuthorNames = "Anurag"
        let actualAuthorNames = viewModel.authorNames
        let isBookmarked = viewModel.isBookmarked
        XCTAssertEqual(expectedAuthorNames, actualAuthorNames)
        XCTAssertFalse(isBookmarked)
    }
    
    func testToggleBookmarkAddsBook() {
        viewModel.isBookmarked = false
        mockPersistenceController.saveBook(mockBook, imageData: mockBook.image)
        viewModel.toggleBookmark()
        XCTAssertTrue(viewModel.isBookmarked)
        XCTAssertTrue(mockPersistenceController.doesBookExist(title: mockBook.title, authors: mockBook.authorName))
    }
    
    func testToggleBookmarkRemovesBook() {
        viewModel.isBookmarked = true
        mockPersistenceController.saveBook(mockBook, imageData: mockBook.image)
        viewModel.toggleBookmark()
        XCTAssertFalse(viewModel.isBookmarked)
        XCTAssertFalse(mockPersistenceController.doesBookExist(title: mockBook.title, authors: mockBook.authorName))
    }
    
    func testFetchInitialStateWhenBookExists() {
        mockPersistenceController.saveBook(mockBook, imageData: mockBook.image)
        viewModel = BookItemViewModel(item: mockBook)
        XCTAssertTrue(viewModel.isBookmarked)
    }
    
    func testFetchInitialStateWhenBookDoesNotExist() {
        viewModel = BookItemViewModel(item: mockBook)
        viewModel.fetchInitialState()
        XCTAssertFalse(viewModel.isBookmarked)
    }
    
    func testConfigureUpdatesImageURL() {
        let newImageUrl = URL(string: "https://example.com/image.jpg")
        viewModel.configure(imageUrl: newImageUrl)
        XCTAssertEqual(viewModel.imageURL, newImageUrl)
    }
    
    func testHandleBookmarkAddedSavesBookWith_ImageData() {
        let expectation = XCTestExpectation(description: "Download and save the image data")
        let imageUrl = URL(string: "https://covers.openlibrary.org/b/id/\(12345)-M.jpg")!
        viewModel = BookItemViewModel(item: mockBook)
        viewModel.configure(imageUrl: imageUrl)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.viewModel.handleBookmarkAdded{
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10) // waiting for 10 secs can help completing test properly
        XCTAssertTrue(self.mockPersistenceController.doesBookExist(title: self.mockBook.title, authors: self.mockBook.authorName))
        XCTAssertTrue(self.mockPersistenceController.doesBookHaveImageData(title: self.mockBook.title, authors: self.mockBook.authorName))
    }
    
    func testHandleBookmarkAddedSavesBookWith_NoImageData() {
        let expectation = XCTestExpectation(description: "Download and save the image data")
        let imageUrl = URL(string: "https://covers.openlibrary.org/b/id/\(-1)-M.jpg")!
        //        viewModel = BookItemViewModel(item: mockBook, controller: mockPersistenceController)
        viewModel.configure(imageUrl: imageUrl)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.viewModel.handleBookmarkAdded{
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10) // waiting for 10 secs can help completing test properly
        XCTAssertTrue(self.mockPersistenceController.doesBookExist(title: self.mockBook.title, authors: self.mockBook.authorName))
        XCTAssertFalse(self.mockPersistenceController.doesBookHaveImageData(title: self.mockBook.title, authors: self.mockBook.authorName))
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
