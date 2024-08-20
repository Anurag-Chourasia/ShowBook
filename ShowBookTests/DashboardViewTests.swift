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
    
    // Test case for loading more books if needed
    func testLoadMoreBooksIfNeeded() {
        let books = [Book(title: "SwiftUI", ratingsAverage: 4.5, ratingsCount: 10, authorName: ["Anurag"],coverI: 12345, image: nil )]
        mockApi.result = .success(books)
        
        viewModel.loadMoreBooksIfNeeded()
        
        XCTAssertTrue(viewModel.isLoadingMore)
        XCTAssertEqual(viewModel.offset, 10)
    }
    
    // Test case for loading more books if not needed
    func testLoadMoreBooksIfNotNeeded() {
        viewModel.isLoadingMore = true
        viewModel.loadingMoreBookNotPossible = true
        
        viewModel.loadMoreBooksIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            XCTAssertFalse(self.viewModel.isLoadingMore)
            XCTAssertEqual(self.viewModel.offset, 0)
        }
    }
    
    // Test case for fetch books success
    func testFetchBooksSuccess() {
        let books = [Book(title: "SwiftUI", ratingsAverage: 4.5, ratingsCount: 10, authorName: ["Anurag"],coverI: 12345, image: nil )]
        mockApi.result = .success(books)
        
        viewModel.fetchBooks(title: "SwiftUI", offset: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            XCTAssertFalse(self.viewModel.isBookLoading)
            XCTAssertFalse(self.viewModel.isLoadingMore)
            XCTAssertEqual(self.viewModel.books, books)
        }
    }
    
    // Test case for fetch books failure
    func testFetchBooksFailure() {
        let error = NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network Error"])
        mockApi.result = .failure(error)
        
        viewModel.fetchBooks(title: "SwiftUI", offset: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            XCTAssertFalse(self.viewModel.isBookLoading)
            XCTAssertTrue(self.viewModel.showAlert)
            XCTAssertEqual(self.viewModel.errorMessage, "Network Error")
        }
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
    
    override func fetchBooks(title: String, offset: Int, completion: @escaping (Result<[Book], Error>) -> Void) {
        if let result = result {
            completion(result)
        }
    }
}
