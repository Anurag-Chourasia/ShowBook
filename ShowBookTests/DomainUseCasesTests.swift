//
//  DomainUseCasesTests.swift
//  ShowBookTests
//

import XCTest
import Combine
@testable import ShowBook

final class DomainUseCasesTests: XCTestCase {

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

        func loadCategory(_ category: DiscoverCategory, refresh: Bool) async throws -> DiscoverResult {
            requestedCategory = category
            requestedRefresh = refresh
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
}
