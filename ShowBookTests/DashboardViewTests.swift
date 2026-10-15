//
//  DashboardViewTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
import SwiftUI
@testable import ShowBook

final class DashboardViewModelTests: XCTestCase {
    var viewModel: DashboardViewModel!
    var userViewModel: UserViewModel!
    var mockApi: MockNetworkClass!
    
    override func setUp() {
        super.setUp()
        mockApi = MockNetworkClass()
        viewModel = DashboardViewModel()
        viewModel.api = mockApi
        userViewModel = UserViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        userViewModel = nil
        mockApi = nil
        super.tearDown()
    }
    
    // Test case for logout alert
    func testLogoutAlertShown() {
        // Given
        viewModel.isLoading = true
        viewModel.logOutAlert = true
        
        // When
        let alertIsPresented = viewModel.logOutAlert
        
        // Then
        XCTAssertTrue(alertIsPresented, "Logout alert should be shown")
    }
    
    func testLogoutAlertDismissal() {
        // Given
        viewModel.isLoading = true
        viewModel.logOutAlert = true
        
        // Simulate user tapping the "Yes" button
        viewModel.logOutAlert = false
        userViewModel.logout()
        
        // When
        let alertIsPresented = viewModel.logOutAlert
        
        // Then
        XCTAssertFalse(alertIsPresented, "Logout alert should be dismissed after logout")
    }
    
    // Test case for filtered books sorting
    func testFilteredBooksSorting() {
        viewModel.searchBook = "Swift"
        viewModel.books = [
            Book(title: "SwiftUI", ratingsAverage: 4.5, ratingsCount: 10, authorName: ["Anurag"],coverI: 12345, image: nil ),
            Book(title: "Combine", ratingsAverage: 4.4, ratingsCount: 34, authorName: ["Chourasia"],coverI: 54321, image: nil )
        ]
        
        viewModel.selectedCategoryFilter = "Title"
        XCTAssertEqual(viewModel.filteredBooks.map { $0.title }, ["Combine", "SwiftUI"])
        
        viewModel.selectedCategoryFilter = "Average"
        XCTAssertEqual(viewModel.filteredBooks.map { $0.title }, ["SwiftUI", "Combine"])
        
        viewModel.selectedCategoryFilter = "Hits"
        XCTAssertEqual(viewModel.filteredBooks.map { $0.title }, ["Combine", "SwiftUI"])
    }
    
    func testPaginationFailureRetriesSameOffset() {
        viewModel.searchBook = "Swift"
        let book = Book(title: "Swift", ratingsAverage: nil, ratingsCount: nil, authorName: nil, coverI: nil, image: nil)
        mockApi.result = .success([book])
        let finished = expectation(description: "retry finishes")
        viewModel.fetchBooks(title: "Swift", offset: 0) {
            self.mockApi.result = .failure(URLError(.notConnectedToInternet))
            self.viewModel.loadMoreBooksIfNeeded {
                XCTAssertEqual(self.viewModel.offset, 0)
                self.mockApi.result = .success([book])
                self.viewModel.loadMoreBooksIfNeeded {
                    XCTAssertEqual(self.mockApi.offsets, [0, 10, 10])
                    XCTAssertEqual(self.viewModel.offset, 10)
                    XCTAssertEqual(self.viewModel.books.count, 2)
                    finished.fulfill()
                }
            }
        }
        wait(for: [finished], timeout: 2)
    }

    func testRejectedPaginationCompletesWithoutRequest() {
        viewModel.isLoadingMore = true
        var completed = false
        viewModel.loadMoreBooksIfNeeded { completed = true }
        XCTAssertTrue(completed)
        XCTAssertTrue(mockApi.offsets.isEmpty)
    }

    func testNewestSearchWinsWhenResponsesArriveOutOfOrder() {
        viewModel.searchBook = "First"
        viewModel.performSearch()
        viewModel.searchBook = "Second"
        viewModel.performSearch()
        XCTAssertEqual(mockApi.pending.count, 2)
        let latest = Book(title: "Second", ratingsAverage: nil, ratingsCount: nil, authorName: nil, coverI: nil, image: nil)
        mockApi.pending[1](.success([latest]))
        mockApi.pending[0](.failure(URLError(.timedOut)))
        let drained = expectation(description: "callbacks drained")
        DispatchQueue.main.async {
            XCTAssertEqual(self.viewModel.books, [latest])
            XCTAssertFalse(self.viewModel.showAlert)
            XCTAssertFalse(self.viewModel.isBookLoading)
            drained.fulfill()
        }
        wait(for: [drained], timeout: 2)
    }

    func testClearingSearchInvalidatesPendingResponse() {
        viewModel.searchBook = "Swift"
        viewModel.performSearch()
        viewModel.searchBook = ""
        viewModel.performSearch()
        mockApi.pending[0](.failure(URLError(.timedOut)))
        let drained = expectation(description: "callbacks drained")
        DispatchQueue.main.async {
            XCTAssertTrue(self.viewModel.books.isEmpty)
            XCTAssertFalse(self.viewModel.showAlert)
            XCTAssertFalse(self.viewModel.isLoadingMore)
            drained.fulfill()
        }
        wait(for: [drained], timeout: 2)
    }

    // Test case for fetch books success
    func testFetchBooksSuccess() {
        let books = [Book(title: "SwiftUI", ratingsAverage: 4.5, ratingsCount: 10, authorName: ["Anurag"], coverI: 12345, image: nil)]
        mockApi.result = .success(books)
        
        let expectation = XCTestExpectation(description: "Books fetched successfully")

        viewModel.fetchBooks(title: "SwiftUI", offset: 0) {
            DispatchQueue.main.async {
                XCTAssertFalse(self.viewModel.isBookLoading)
                XCTAssertFalse(self.viewModel.isLoadingMore)
                XCTAssertEqual(self.viewModel.books, books)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }
    
    // Test case for fetch books failure
    func testFetchBooksFailure() {
        let error = NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network Error"])
        mockApi.result = .failure(error)
        
        let expectation = XCTestExpectation(description: "Fetch books fails and updates state")

        viewModel.fetchBooks(title: "SwiftUI", offset: 0) {
            DispatchQueue.main.async {
                XCTAssertFalse(self.viewModel.isBookLoading)
                XCTAssertTrue(self.viewModel.showAlert)
                XCTAssertEqual(self.viewModel.errorMessage, "Network Error")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }
    
    // Test case for perform search
    func testPerformSearch() {
        viewModel.searchBook = "Swift"
        mockApi.result = .success([]) // Mocking empty result
        
        viewModel.performSearch()
        
        XCTAssertTrue(viewModel.isBookLoading)
        XCTAssertEqual(viewModel.offset, 0)
    }
}

class MockNetworkClass: NetworkClass {
    var result: Result<[Book], Error>?
    var offsets: [Int] = []
    var pending: [(Result<[Book], Error>) -> Void] = []
    
    override func fetchBooks(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) {
        offsets.append(offset)
        pending.append(completion)
        if let result = result {
            completion(result)
        }
    }
}
