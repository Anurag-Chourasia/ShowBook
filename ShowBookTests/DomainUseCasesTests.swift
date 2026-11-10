//
//  DomainUseCasesTests.swift
//  ShowBookTests
//

import XCTest
import Combine
import CoreData
import LocalizationKit
@testable import ShowBook

// MARK: - Mock URLProtocol for NetworkClass Tests
private final class MockNetworkProtocol: URLProtocol {
    static var responseData: Data?
    static var statusCode: Int = 200
    static var responseError: Error?
    static var lastURL: URL?
    static var onRequest: (() -> Void)?

    static func reset() {
        responseData = nil
        statusCode = 200
        responseError = nil
        lastURL = nil
        onRequest = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        MockNetworkProtocol.lastURL = request.url
        MockNetworkProtocol.onRequest?()

        if let error = MockNetworkProtocol.responseError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let url = request.url {
            let response = HTTPURLResponse(url: url, statusCode: MockNetworkProtocol.statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data = MockNetworkProtocol.responseData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class DomainUseCasesTests: XCTestCase {

    override func tearDown() {
        MockNetworkProtocol.reset()
        super.tearDown()
    }

    // MARK: - Dashboard / SearchBooksUseCase Tests

    private final class MockBookSearchRepository: BookSearchRepositoryProtocol {
        var resultToReturn: Result<[Book], Error> = .success([])
        var searchedTitle: String?
        var searchedOffset: Int?

        func searchBooks(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) -> Task<Void, Never>? {
            searchedTitle = title
            searchedOffset = offset
            completion(resultToReturn)
            return nil
        }
    }

    func testSearchBooksUseCaseSuccess() {
        let mockRepo = MockBookSearchRepository()
        let expectedBook = Book(title: "Domain Driven Design", ratingsAverage: 4.9, ratingsCount: 100, authorName: ["Eric Evans"], coverI: 1, image: nil)
        mockRepo.resultToReturn = .success([expectedBook])

        let useCase = SearchBooksUseCase(repository: mockRepo)
        var receivedResult: Result<[Book], Error>?
        _ = useCase.execute(title: "Domain", offset: 0) { result in
            receivedResult = result
        }

        XCTAssertEqual(mockRepo.searchedTitle, "Domain")
        XCTAssertEqual(mockRepo.searchedOffset, 0)
        switch receivedResult {
        case .success(let books):
            XCTAssertEqual(books.count, 1)
            XCTAssertEqual(books.first?.title, "Domain Driven Design")
        case .failure, .none:
            XCTFail("Expected success but got \(String(describing: receivedResult))")
        }
    }

    func testSearchBooksUseCaseFailure() {
        struct DummyError: Error, Equatable {}
        let mockRepo = MockBookSearchRepository()
        mockRepo.resultToReturn = .failure(DummyError())

        let useCase = SearchBooksUseCase(repository: mockRepo)
        var receivedResult: Result<[Book], Error>?
        _ = useCase.execute(title: "Failing", offset: 10) { result in
            receivedResult = result
        }

        XCTAssertEqual(mockRepo.searchedTitle, "Failing")
        XCTAssertEqual(mockRepo.searchedOffset, 10)
        switch receivedResult {
        case .failure:
            break // Expected
        case .success, .none:
            XCTFail("Expected failure")
        }
    }

    // MARK: - Discover / FetchDiscoverCategoryUseCase Tests

    private final class MockDiscoverRepository: DiscoverRepositoryProtocol {
        var resultToReturn: DiscoverResult = DiscoverResult(books: [], cached: false, savedAt: Date())
        var requestedCategory: DiscoverCategory?
        var requestedRefresh: Bool?
        var shouldThrow: Bool = false

        func loadCategory(_ category: DiscoverCategory, refresh: Bool) async throws -> DiscoverResult {
            requestedCategory = category
            requestedRefresh = refresh
            if shouldThrow {
                throw URLError(.timedOut)
            }
            return resultToReturn
        }
    }

    func testFetchDiscoverCategoryUseCase() async throws {
        let mockRepo = MockDiscoverRepository()
        let expectedBook = Book(title: "Sci-Fi Classic", ratingsAverage: 4.5, ratingsCount: 42, authorName: ["Author"], coverI: 2, image: nil)
        let now = Date()
        mockRepo.resultToReturn = DiscoverResult(books: [expectedBook], cached: true, savedAt: now)

        let useCase = FetchDiscoverCategoryUseCase(repository: mockRepo)
        let result = try await useCase.execute(category: .science, refresh: true)

        XCTAssertEqual(mockRepo.requestedCategory, .science)
        XCTAssertEqual(mockRepo.requestedRefresh, true)
        XCTAssertEqual(result.books.count, 1)
        XCTAssertEqual(result.books.first?.title, "Sci-Fi Classic")
        XCTAssertTrue(result.cached)
        XCTAssertEqual(result.savedAt, now)
    }

    // MARK: - Bookmark Use Cases Tests

    private final class MockBookmarkRepository: BookmarkRepositoryProtocol {
        var books: [Book] = []
        var savedBook: Book?
        var deletedBook: Book?

        var updatedBooksPublisher: AnyPublisher<[Book]?, Never> {
            Just(books).eraseToAnyPublisher()
        }

        func fetchBooks() -> [Book] {
            return books
        }

        func saveBook(_ book: Book, imageData: Data?) {
            savedBook = book
            books.append(book)
        }

        func isBookmarked(_ book: Book) -> Bool {
            return books.contains(where: { $0.title == book.title })
        }

        func deleteBook(_ book: Book) {
            deletedBook = book
            books.removeAll(where: { $0.title == book.title })
        }

        func deleteAllBooks() {
            books.removeAll()
        }

        func doesBookExist(title: String, authors: [String]?) -> Bool {
            return books.contains(where: { $0.title == title })
        }

        func doesBookHaveImageData(title: String, authors: [String]?) -> Bool {
            return false
        }

        func rekeyBookmarks(fromEmail: String, toUUID: UUID) throws -> Int {
            return 0
        }
    }

    func testFetchBookmarksUseCase() {
        let mockRepo = MockBookmarkRepository()
        let book = Book(title: "Saved Book", ratingsAverage: 4.0, ratingsCount: 10, authorName: ["Author"], coverI: 3, image: nil)
        mockRepo.books = [book]

        let useCase = FetchBookmarksUseCase(repository: mockRepo)
        let result = useCase.execute()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Saved Book")
    }

    func testToggleBookmarkUseCase() {
        let mockRepo = MockBookmarkRepository()
        let book = Book(title: "Toggle Book", ratingsAverage: 3.5, ratingsCount: 5, authorName: ["Author"], coverI: 4, image: nil)

        let useCase = ToggleBookmarkUseCase(repository: mockRepo)

        XCTAssertFalse(useCase.isBookmarked(book))

        useCase.saveBookmark(book, imageData: nil)
        XCTAssertEqual(mockRepo.savedBook?.title, "Toggle Book")
        XCTAssertTrue(useCase.isBookmarked(book))

        useCase.deleteBookmark(book)
        XCTAssertEqual(mockRepo.deletedBook?.title, "Toggle Book")
        XCTAssertFalse(useCase.isBookmarked(book))
    }

    // MARK: - BookDetails Use Cases Tests

    private final class MockBookDetailsRepository: BookDetailsRepositoryProtocol {
        var workToReturn = LibraryWork(key: "works/OL123W", title: "Test Work")
        var editionsToReturn = LibraryEditions(size: 1, entries: [LibraryEdition(key: "books/OL123M", title: "Test Edition")])

        func work(key: String) async throws -> LibraryWork {
            return workToReturn
        }

        func editions(key: String, offset: Int) async throws -> LibraryEditions {
            return editionsToReturn
        }

        func edition(key: String) async throws -> LibraryEdition {
            return editionsToReturn.entries[0]
        }
    }

    func testFetchBookDetailsAndEditionsUseCases() async throws {
        let mockRepo = MockBookDetailsRepository()

        let detailsUseCase = FetchBookDetailsUseCase(repository: mockRepo)
        let work = try await detailsUseCase.execute(key: "works/OL123W")
        XCTAssertEqual(work.key, "works/OL123W")
        XCTAssertEqual(work.title, "Test Work")

        let editionsUseCase = FetchBookEditionsUseCase(repository: mockRepo)
        let editions = try await editionsUseCase.execute(key: "works/OL123W", offset: 0)
        XCTAssertEqual(editions.size, 1)
        XCTAssertEqual(editions.entries.first?.key, "books/OL123M")
        XCTAssertEqual(editions.entries.first?.title, "Test Edition")
    }

    // MARK: - NetworkClass Tests

    private func makeNetworkSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockNetworkProtocol.self]
        return URLSession(configuration: config)
    }

    func testNetworkClassFetchCountriesSuccess() {
        let json = """
        {
            "status": "OK",
            "status-code": 200,
            "version": "1.0",
            "access": "public",
            "total": 1,
            "offset": 0,
            "limit": 10,
            "data": {
                "US": { "country": "United States", "region": "Americas" }
            }
        }
        """
        MockNetworkProtocol.responseData = Data(json.utf8)
        let session = makeNetworkSession()
        let network = NetworkClass(session: session)

        let exp = expectation(description: "Fetch countries success")
        network.fetchCountries { countryModel, error in
            XCTAssertNil(error)
            XCTAssertNotNil(countryModel)
            XCTAssertEqual(countryModel?.status, "OK")
            XCTAssertEqual(countryModel?.data["US"]?.country, "United States")
            XCTAssertEqual(countryModel?.data["US"]?.region.rawValue, "Americas")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testNetworkClassFetchCountriesError() {
        MockNetworkProtocol.responseError = URLError(.notConnectedToInternet)
        let session = makeNetworkSession()
        let network = NetworkClass(session: session)

        let exp = expectation(description: "Fetch countries error")
        network.fetchCountries { countryModel, error in
            XCTAssertNil(countryModel)
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testNetworkClassFetchCountriesDecodingError() {
        MockNetworkProtocol.responseData = Data("invalid json".utf8)
        let session = makeNetworkSession()
        let network = NetworkClass(session: session)

        let exp = expectation(description: "Fetch countries decoding error")
        network.fetchCountries { countryModel, error in
            XCTAssertNil(countryModel)
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testNetworkClassFetchCountriesNoData() {
        MockNetworkProtocol.responseData = Data()
        let session = makeNetworkSession()
        let network = NetworkClass(session: session)

        let exp = expectation(description: "Fetch countries empty data")
        network.fetchCountries { countryModel, error in
            XCTAssertNil(countryModel)
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testNetworkClassFetchBooksSuccess() {
        let json = """
        {
            "docs": [
                {
                    "key": "/works/OL1W",
                    "title": "Swift Programming",
                    "author_name": ["Apple"],
                    "cover_i": 42,
                    "ratings_average": 4.8,
                    "ratings_count": 150
                }
            ]
        }
        """
        MockNetworkProtocol.responseData = Data(json.utf8)
        let session = makeNetworkSession()
        let network = NetworkClass(session: session)

        let exp = expectation(description: "Fetch books success")
        network.fetchBooks(title: "Swift + C++ & More", offset: 0) { result in
            switch result {
            case .success(let books):
                XCTAssertEqual(books.count, 1)
                XCTAssertEqual(books.first?.title, "Swift Programming")
                XCTAssertEqual(books.first?.coverI, 42)
            case .failure(let error):
                XCTFail("Unexpected failure: \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testNetworkClassFetchBooksError() {
        MockNetworkProtocol.responseError = URLError(.timedOut)
        let session = makeNetworkSession()
        let network = NetworkClass(session: session)

        let exp = expectation(description: "Fetch books error")
        network.fetchBooks(title: "Swift", offset: 0) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testNetworkClassFetchBooksDecodingError() {
        MockNetworkProtocol.responseData = Data("malformed json".utf8)
        let session = makeNetworkSession()
        let network = NetworkClass(session: session)

        let exp = expectation(description: "Fetch books decoding error")
        network.fetchBooks(title: "Swift", offset: 0) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testNetworkClassFetchBooksNoData() {
        MockNetworkProtocol.responseData = Data()
        let session = makeNetworkSession()
        let network = NetworkClass(session: session)

        let exp = expectation(description: "Fetch books empty data")
        network.fetchBooks(title: "Swift", offset: 0) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testNetworkSemanticErrorProperties() {
        XCTAssertEqual(NetworkSemanticError.invalidURL.localizationKey, "showbook.error.invalid_url")
        XCTAssertEqual(NetworkSemanticError.noDataReceived.localizationKey, "showbook.error.no_data_received")
        XCTAssertNotEqual(NetworkSemanticError.invalidURL, NetworkSemanticError.noDataReceived)
    }

    // MARK: - DiscoverViewModel Tests

    @MainActor
    func testDiscoverViewModelLoadSuccess() async {
        let mockRepo = MockDiscoverRepository()
        let expectedBook = Book(title: "Discover Book", ratingsAverage: 4.0, ratingsCount: 10, authorName: ["Author"], coverI: 1, image: nil)
        let savedDate = Date()
        mockRepo.resultToReturn = DiscoverResult(books: [expectedBook], cached: true, savedAt: savedDate)

        let viewModel = DiscoverViewModel(service: mockRepo)
        await viewModel.load(.fiction, refresh: false)

        XCTAssertEqual(viewModel.books.count, 1)
        XCTAssertEqual(viewModel.books.first?.title, "Discover Book")
        XCTAssertFalse(viewModel.loading)
        XCTAssertNil(viewModel.message)
        XCTAssertEqual(viewModel.cachedAt, savedDate)
    }

    @MainActor
    func testDiscoverViewModelLoadFailure() async {
        let mockRepo = MockDiscoverRepository()
        mockRepo.shouldThrow = true

        let viewModel = DiscoverViewModel(service: mockRepo)
        await viewModel.load(.history, refresh: true)

        XCTAssertTrue(viewModel.books.isEmpty)
        XCTAssertFalse(viewModel.loading)
        XCTAssertEqual(viewModel.message, String(\.errorCategoryFailed))
        XCTAssertNil(viewModel.cachedAt)
    }

    // MARK: - BookmarkViewModel & BookmarkButtonViewModel Tests

    func testBookmarkViewModelEmptyAndErrorStates() {
        let persistence = PersistenceController.inMemory()
        persistence.deleteAllBooks()

        let viewModel = BookmarkViewModel(persistenceController: persistence)
        viewModel.loadBookmarks()

        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.errorMessage, String(\.errorNoRecordFound))

        // Simulate store load error
        persistence.storeLoadError = NSError(domain: "TestDomain", code: 999)
        viewModel.loadBookmarks()
        XCTAssertTrue(viewModel.showAlert)
        XCTAssertEqual(viewModel.errorMessage, String(\.errorStorageUnavailable))

        // Set up persistence controller methods
        let persistence2 = PersistenceController.inMemory()
        viewModel.setUpPersistenceController(controller: persistence2)
        viewModel.setUpPersitenceController(controller: persistence2)
    }

    func testBookmarkButtonViewModelLifecycle() {
        let persistence = PersistenceController.inMemory()
        let viewModel = BookmarkButtonViewModel(persistenceController: persistence)

        let book = Book(title: "Button Book", ratingsAverage: 4.0, ratingsCount: 1, authorName: ["Author"], coverI: 1, image: nil)
        viewModel.configure(book: book, imageUrl: nil)
        XCTAssertFalse(viewModel.isBookmarked)

        let persistence2 = PersistenceController.inMemory()
        viewModel.setUpPersistenceController(controller: persistence2)
        viewModel.setUpPersitenceController(controller: persistence2)
    }

    // MARK: - UserPreferenceRepositoryImpl Tests

    func testUserPreferenceRepository() {
        let persistence = PersistenceController.inMemory()
        let repo = UserPreferenceRepositoryImpl(persistenceController: persistence)

        let model = CountryModel(
            status: "OK",
            statusCode: 200,
            version: "1",
            access: "public",
            total: 1,
            offset: 0,
            limit: 10,
            data: ["AU": Datum(country: "Australia", region: Region(rawValue: "Oceania"))]
        )
        repo.saveCountryModel(model)
        let fetched = repo.fetchCountryModel()
        XCTAssertEqual(fetched?.status, "OK")
        XCTAssertEqual(fetched?.data["Australia"]?.country, "Australia")

        repo.saveDefaultCountryName(selectedCountryName: "Australia")
        XCTAssertEqual(repo.fetchSelectedCountryName(), "Australia")
    }

    // MARK: - BookmarkRepositoryImpl Tests

    func testBookmarkRepositoryOperations() {
        let persistence = PersistenceController.inMemory()
        let repo = BookmarkRepositoryImpl(persistenceController: persistence)

        repo.deleteAllBooks()
        XCTAssertEqual(repo.fetchBooks().count, 0)

        let book = Book(title: "Repo Book", ratingsAverage: 4.2, ratingsCount: 5, authorName: ["Author A"], coverI: 10, image: nil)
        repo.saveBook(book, imageData: nil)

        XCTAssertTrue(repo.isBookmarked(book))
        XCTAssertTrue(repo.doesBookExist(title: "Repo Book", authors: ["Author A"]))
        XCTAssertFalse(repo.doesBookHaveImageData(title: "Repo Book", authors: ["Author A"]))
        XCTAssertEqual(repo.fetchBooks().count, 1)

        repo.deleteBook(book)
        XCTAssertFalse(repo.isBookmarked(book))

        repo.saveBook(book, imageData: nil)
        repo.deleteAllBooks()
        XCTAssertEqual(repo.fetchBooks().count, 0)

        let cancellable = repo.updatedBooksPublisher.sink { _ in }
        cancellable.cancel()
    }

    // MARK: - Models & Entities Tests

    func testRegionCodableAndConstants() throws {
        let regions: [Region] = [.africa, .antarctic, .asia, .centralAmerica, Region(rawValue: "CustomRegion")]
        for region in regions {
            let data = try JSONEncoder().encode(region)
            let decoded = try JSONDecoder().decode(Region.self, from: data)
            XCTAssertEqual(region, decoded)
            XCTAssertEqual(region.hashValue, decoded.hashValue)
        }
    }

    func testDiscoverEntitiesProperties() {
        for category in DiscoverCategory.allCases {
            XCTAssertFalse(category.id.isEmpty)
            XCTAssertFalse(category.rawValue.isEmpty)
        }

        let result = DiscoverResult(books: [], cached: true, savedAt: Date())
        XCTAssertTrue(result.cached)
        XCTAssertTrue(result.books.isEmpty)
    }

    func testBookDetailsEntities() {
        let desc = LibraryText(value: "A wonderful book")
        let work = LibraryWork(
            key: "W1",
            title: "Work Title",
            description: desc,
            subjects: ["Fiction"],
            covers: [100, 200],
            first_publish_date: "2020"
        )
        XCTAssertEqual(work.title, "Work Title")
        XCTAssertEqual(work.description?.value, "A wonderful book")
        XCTAssertEqual(work.subjects, ["Fiction"])
        XCTAssertEqual(work.covers, [100, 200])
        XCTAssertEqual(work.first_publish_date, "2020")

        let workWithSimpleDesc = LibraryWork(key: "W2", title: "Work 2")
        XCTAssertNil(workWithSimpleDesc.description)
        XCTAssertNil(workWithSimpleDesc.covers)

        let edition = LibraryEdition(
            key: "E1",
            title: "Edition 1",
            publishers: ["ShowBook Press"],
            publish_date: "2024",
            number_of_pages: 350,
            physical_format: "Paperback",
            isbn_10: ["1234567890"],
            isbn_13: ["1234567890123"],
            languages: [LibraryEdition.Reference(key: "eng")],
            covers: [50]
        )
        XCTAssertEqual(edition.number_of_pages, 350)
        XCTAssertEqual(edition.publish_date, "2024")
        XCTAssertEqual(edition.publishers, ["ShowBook Press"])
        XCTAssertEqual(edition.covers, [50])
        XCTAssertEqual(edition.isbn_13, ["1234567890123"])
        XCTAssertEqual(edition.id, "E1")

        let errors: [BookDetailsError] = [.invalidKey, .notFound, .rateLimited, .serverError(statusCode: 500), .unreadable]
        for err in errors {
            XCTAssertNotNil(err.errorDescription)
        }
    }

    // MARK: - PersistenceController Methods Tests

    func testPersistenceControllerDirectMethods() {
        let persistence = PersistenceController.inMemory()
        PersistenceController.invalidateBookmarkSession()

        _ = persistence.bookmarkOwner
        _ = persistence.currentUserUUID
        _ = persistence.currentUserEmail
        _ = persistence.isStoreLoaded

        let country = CountryModel(
            status: "OK",
            statusCode: 200,
            version: "1",
            access: "public",
            total: 1,
            offset: 0,
            limit: 10,
            data: ["NO": Datum(country: "Norway", region: Region(rawValue: "Europe"))]
        )
        persistence.saveCountryModel(country)
        XCTAssertEqual(persistence.fetchCountryModel()?.status, "OK")

        persistence.saveDefaultCountryName(selectedCountryName: "Norway")
        XCTAssertEqual(persistence.fetchSelectedCountryName(), "Norway")

        let book = Book(title: "Direct Persist Book", ratingsAverage: 4.5, ratingsCount: 2, authorName: ["Author B"], coverI: 5, image: nil)
        persistence.saveBook(book, imageData: nil)
        XCTAssertNotNil(persistence.bookExists(book))
        XCTAssertTrue(persistence.doesBookExist(title: "Direct Persist Book", authors: ["Author B"]))
        XCTAssertFalse(persistence.doesBookHaveImageData(title: "Direct Persist Book", authors: ["Author B"]))

        persistence.deleteBook(book)
        persistence.deleteAllBooks()
        XCTAssertEqual(persistence.fetchBooks().count, 0)
    }
}
