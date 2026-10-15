//
//  BookItemViewModelTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
import Combine
import CoreData
import SwiftUI
import UIKit
import UIComponentsKit
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


@MainActor final class BookCatalogRenderingTests: XCTestCase {
    func testListGridAndAccessibleCardsRenderInBothAppearances() throws {
        let book = Book(title: "A long book title that remains readable in list and grid",
                        ratingsAverage: 4.5, ratingsCount: 123, authorName: ["Example Author"], coverI: nil, image: nil)
        for (name, layout, width, type, scheme) in [
            ("phone-list-light", CatalogLayout.list, CGFloat(361), DynamicTypeSize.large, ColorScheme.light),
            ("phone-grid-light", .grid, CGFloat(170), .large, .light),
            ("tablet-grid-dark", .grid, CGFloat(210), .large, .dark),
            ("accessible-phone-list-dark", .list, CGFloat(361), .accessibility5, .dark),
            ("accessible-list-dark", .list, CGFloat(736), .accessibility5, .dark)
        ] {
            let view = BookItem(item: book, layout: layout)
                .frame(width: width)
                .environment(\.dynamicTypeSize, type)
                .environment(\.colorScheme, scheme)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            XCTAssertGreaterThan(image.size.height, 0)
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}

private actor DetailsFixture: BookDetailsServing {
    var offsets: [Int] = []
    var failNextPage = true
    func work(key: String) async throws -> LibraryWork {
        try JSONDecoder().decode(LibraryWork.self, from: Data(#"{"key":"/works/OL1W","title":"Fixture","description":{"value":"Description"}}"#.utf8))
    }
    func edition(key: String) async throws -> LibraryEdition {
        try JSONDecoder().decode(LibraryEdition.self, from: Data(#"{"key":"/books/OL1M","title":"Edition"}"#.utf8))
    }
    func editions(key: String, offset: Int) async throws -> LibraryEditions {
        offsets.append(offset)
        if failNextPage { failNextPage = false; throw URLError(.notConnectedToInternet) }
        let id = offset == 0 ? "OL1M" : "OL2M"
        return try JSONDecoder().decode(LibraryEditions.self, from: Data("{\"size\":2,\"entries\":[{\"key\":\"/books/\(id)\",\"title\":\"Edition\"}]}".utf8))
    }
}

@MainActor final class BookDetailsTests: XCTestCase {
    func testSearchDecodesWorkKeyAndOldDataStillDecodes() throws {
        let decoder = JSONDecoder()
        let book = try decoder.decode(Book.self, from: Data(#"{"key":"/works/OL1W","title":"Book"}"#.utf8))
        XCTAssertEqual(book.key, "/works/OL1W")
        XCTAssertNil(try decoder.decode(Book.self, from: Data(#"{"title":"Old book"}"#.utf8)).key)
    }
    func testDescriptionVariantsAndSparseEditions() throws {
        for json in [#"{"key":"/works/OL1W","title":"Book","description":"Plain"}"#,
                     #"{"key":"/works/OL1W","title":"Book","description":{"type":"/type/text","value":"Plain"}}"#] {
            XCTAssertEqual(try JSONDecoder().decode(LibraryWork.self, from: Data(json.utf8)).description?.value, "Plain")
        }
        let edition = try JSONDecoder().decode(LibraryEdition.self, from: Data(#"{"key":"/books/OL1M","title":"Book"}"#.utf8))
        XCTAssertNil(edition.number_of_pages)
        XCTAssertNil(edition.publish_date)
    }
    func testEditionsFailureKeepsWorkAndRetriesSamePage() async throws {
        let fixture = DetailsFixture()
        let model = BookDetailsViewModel(key: "/works/OL1W", service: fixture)
        await model.load()
        XCTAssertEqual(model.work?.title, "Fixture")
        XCTAssertNotNil(model.editionsError)
        XCTAssertNil(model.error)
        await model.loadMoreEditions()
        XCTAssertEqual(model.editions.count, 1)
        XCTAssertNil(model.editionsError)
        await model.loadMoreEditions()
        XCTAssertEqual(model.editions.count, 2)
        XCTAssertFalse(model.hasMoreEditions)
        await model.loadMoreEditions()
        let offsets = await fixture.offsets
        XCTAssertEqual(offsets, [0, 0, 1])
    }
    func testLegacyBookmarkDoesNotGuessWorkFromTitle() async {
        let model = BookDetailsViewModel(key: nil, service: DetailsFixture())
        await model.load()
        XCTAssertNil(model.work)
        XCTAssertNotNil(model.error)
        XCTAssertFalse(model.loading)
    }
    func testWorkKeysAreValidatedBeforeBuildingURLs() {
        XCTAssertTrue(BookDetailsService.validKey("/works/OL45804W", resource: "works"))
        for key in ["https://evil.example/works/OL1W", "/works/../OL1W", "/works/OL1W?x=y", "/books/OL1M"] {
            XCTAssertFalse(BookDetailsService.validKey(key, resource: "works"))
        }
    }
    func testBookmarkWorkKeyRoundTripsAndSeparatesSameTitles() throws {
        let persistence = PersistenceController(container: PersistenceController.createInMemoryPersistentContainer())
        let oldEmail = UserDefaults.standard.string(forKey: "LoggedInUserEmail")
        UserDefaults.standard.set("details-fixture@example.com", forKey: "LoggedInUserEmail")
        defer { UserDefaults.standard.set(oldEmail, forKey: "LoggedInUserEmail") }
        let first = Book(title: "Same title", ratingsAverage: nil, ratingsCount: nil, authorName: nil, coverI: nil, image: nil, key: "/works/OL1W")
        let second = Book(title: "Same title", ratingsAverage: nil, ratingsCount: nil, authorName: nil, coverI: nil, image: nil, key: "/works/OL2W")
        persistence.saveBook(first, imageData: nil)
        persistence.saveBook(second, imageData: nil)
        XCTAssertEqual(Set(persistence.fetchBooks().compactMap(\.key)), ["/works/OL1W", "/works/OL2W"])
        persistence.deleteBook(first)
        XCTAssertEqual(persistence.fetchBooks().map(\.key), ["/works/OL2W"])
    }
}

private final class DetailsRequestLog: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [URLRequest] = []
    func append(_ request: URLRequest) { lock.lock(); defer { lock.unlock() }; stored.append(request) }
    var requests: [URLRequest] { lock.lock(); defer { lock.unlock() }; return stored }
}
private final class DetailsURLProtocol: URLProtocol {
    static let log = DetailsRequestLog()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.log.append(request)
        let path = request.url!.path
        let status = path.contains("OL404W") ? 404 : path.contains("OL429W") ? 429 : 200
        let body: String
        if status != 200 { body = "<html>unavailable</html>" }
        else if path.hasSuffix("editions.json") { body = #"{"size":0,"entries":[]}"# }
        else if path.contains("/books/") { body = #"{"key":"/books/OL999M","title":"Sparse edition"}"# }
        else { body = #"{"key":"/works/OL999W","title":"Cached work","description":"Text"}"# }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
extension BookDetailsTests {
    func testServiceRequestsCachesAndMapsHTTPFailures() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DetailsURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let service = BookDetailsService(session: session)
        let before = DetailsURLProtocol.log.requests.count
        _ = try await service.work(key: "/works/OL999W")
        _ = try await service.work(key: "/works/OL999W")
        XCTAssertEqual(DetailsURLProtocol.log.requests.count - before, 1)
        _ = try await service.editions(key: "/works/OL999W", offset: 20)
        let pageRequest = try XCTUnwrap(DetailsURLProtocol.log.requests.last)
        XCTAssertEqual(pageRequest.url?.path, "/works/OL999W/editions.json")
        XCTAssertEqual(URLComponents(url: pageRequest.url!, resolvingAgainstBaseURL: false)?.queryItems,
                       [URLQueryItem(name: "limit", value: "20"), URLQueryItem(name: "offset", value: "20")])
        XCTAssertTrue(pageRequest.value(forHTTPHeaderField: "User-Agent")?.hasPrefix("ShowBook") == true)
        let edition = try await service.edition(key: "/books/OL999M")
        XCTAssertEqual(edition.title, "Sparse edition")
        for (key, expected) in [("/works/OL404W", "no longer available"), ("/works/OL429W", "Please wait")] {
            do { _ = try await service.work(key: key); XCTFail("Expected HTTP error") }
            catch { XCTAssertTrue(BookDetailsViewModel.message(error).contains(expected)) }
        }
        let cancelled = Task {
            try Task.checkCancellation()
            return try await service.work(key: "/works/OL998W")
        }
        cancelled.cancel()
        do { _ = try await cancelled.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    func testDetailsRenderAtPhoneAndAccessibilitySizes() async throws {
        let fixture = DetailsFixture()
        let model = BookDetailsViewModel(key: "/works/OL1W", service: fixture)
        await model.load()
        await model.loadMoreEditions()
        let book = Book(title: "A book with a long title", ratingsAverage: nil, ratingsCount: nil, authorName: ["Example Author"], coverI: nil, image: nil, key: "/works/OL1W")
        for (name, size, appearance) in [("details-phone", DynamicTypeSize.large, ColorScheme.light), ("details-accessibility", .accessibility5, .dark)] {
            let view = NavigationStack { BookDetailsView(book: book, model: model) }
                .environment(\.dynamicTypeSize, size)
                .environment(\.colorScheme, appearance)
            let controller = UIHostingController(rootView: view)
            let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
            let previousWindow = scene.windows.first(where: \.isKeyWindow)
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.frame = window.bounds
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 300_000_000)
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                XCTAssertTrue(window.drawHierarchy(in: window.bounds, afterScreenUpdates: true))
            }
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
