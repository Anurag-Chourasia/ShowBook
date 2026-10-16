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
    
    func testSearchStatesDistinguishInitialShortEmptyAndFailure() {
        XCTAssertEqual(viewModel.searchState, .idle)
        viewModel.searchBook = "   "
        viewModel.performSearch()
        XCTAssertEqual(viewModel.searchState, .idle)
        XCTAssertTrue(mockApi.pending.isEmpty)
        viewModel.searchBook = "ab"
        viewModel.performSearch()
        XCTAssertEqual(viewModel.searchState, .tooShort)
        XCTAssertTrue(mockApi.pending.isEmpty)
        viewModel.searchBook = "Unknown title"
        viewModel.performSearch()
        XCTAssertEqual(viewModel.searchState, .loading)
        mockApi.pending[0](.success([]))
        let drained = expectation(description: "empty then failed search")
        DispatchQueue.main.async {
            XCTAssertEqual(self.viewModel.searchState, .empty)
            self.viewModel.searchBook = "Another title"
            self.viewModel.performSearch()
            XCTAssertEqual(self.viewModel.searchState, .loading)
            self.mockApi.pending[1](.failure(URLError(.notConnectedToInternet)))
            DispatchQueue.main.async {
                XCTAssertEqual(self.viewModel.searchState, .failed)
                self.viewModel.searchBook = ""
                self.viewModel.performSearch()
                XCTAssertEqual(self.viewModel.searchState, .idle)
                drained.fulfill()
            }
        }
        wait(for: [drained], timeout: 2)
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
            XCTAssertEqual(self.viewModel.searchState, .results)
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

@MainActor
final class SearchNavigationRenderingTests: XCTestCase {
    func testSearchBannersAndNativeLoginNavigationRender() async throws {
        let user = UserViewModel()
        let model = DashboardViewModel()
        let api = MockNetworkClass()
        model.api = api
        try await capture(DashboardView().environmentObject(model).environmentObject(user), name: "search-start")
        model.searchBook = "No matching book"
        api.result = .success([])
        model.performSearch()
        await Task.yield()
        try await capture(DashboardView().environmentObject(model).environmentObject(user)
            .environment(\.dynamicTypeSize, .accessibility3), name: "search-empty-accessibility")
        try await capture(NavigationStack(path: .constant(["login"])) {
            Text("Welcome").navigationTitle("Welcome")
                .navigationDestination(for: String.self) { _ in LoginView() }
        }.environmentObject(user), name: "login-native-navigation")
    }

    func testDeveloperScreenResourcesAndAccessibilityRender() async throws {
        try await capture(NavigationStack { ShowBookDeveloperView() }, name: "developer-profile")
        try await capture(NavigationStack { ShowBookDeveloperView() }
            .environment(\.dynamicTypeSize, .accessibility3)
            .environment(\.colorScheme, .dark), name: "developer-profile-accessibility")
    }

    func testAppearanceSwitchesBothDirectionsAndReturnsToSystem() async throws {
        let suite = "showbook-appearance-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView:
            NavigationStack { Text("Appearance fixture").showBookTools() }
                .appAppearance().defaultAppStorage(defaults))
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        for selection in [AppAppearance.dark, .light, .dark, .system, .light, .system] {
            defaults.set(selection.rawValue, forKey: "appAppearance")
            try await Task.sleep(nanoseconds: 150_000_000)
            XCTAssertEqual(window.overrideUserInterfaceStyle, selection.interfaceStyle)
            if selection != .system {
                XCTAssertEqual(window.rootViewController?.traitCollection.userInterfaceStyle, selection.interfaceStyle)
            }
        }
    }

    func testCoverPreviewSavedImageAndUnavailableRender() async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 300)).image { context in
            UIColor.systemIndigo.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 300))
        }
        try await capture(BookCoverPreview(coverID: nil, savedImage: image.pngData(), title: "Saved book cover")
            .environment(\.colorScheme, .dark), name: "cover-preview-saved-dark")
        try await capture(BookCoverPreview(coverID: nil, savedImage: nil, title: "Missing cover")
            .environment(\.dynamicTypeSize, .accessibility3), name: "cover-preview-missing-accessibility")
    }

    private func capture<V: View>(_ view: V, name: String) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        try await Task.sleep(nanoseconds: 400_000_000)
        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            XCTAssertTrue(window.drawHierarchy(in: window.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
