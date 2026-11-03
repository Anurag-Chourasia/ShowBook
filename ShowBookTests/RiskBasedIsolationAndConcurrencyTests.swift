//
//  RiskBasedIsolationAndConcurrencyTests.swift
//  ShowBookTests
//
//  Risk-based isolation, migration, and concurrency coverage (IOS-23)
//

import XCTest
import CoreData
@testable import ShowBook

final class RiskBasedIsolationAndConcurrencyTests: XCTestCase {
    var persistence: PersistenceController!
    var userViewModel: UserViewModel!
    var bookmarkViewModel: BookmarkViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        UserDefaults.standard.removeObject(forKey: "developer.authentication")

        persistence = PersistenceController(container: PersistenceController.createInMemoryPersistentContainer())
        userViewModel = UserViewModel()
        userViewModel.setUpPersistenceController(controller: persistence)
        bookmarkViewModel = BookmarkViewModel()
        bookmarkViewModel.setUpPersitenceController(controller: persistence)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        UserDefaults.standard.removeObject(forKey: "developer.authentication")
        persistence = nil
        userViewModel = nil
        bookmarkViewModel = nil
        super.tearDown()
    }

    // MARK: - Account Isolation & Sign-Out Cache Eviction

    func testSignOutPurgesInMemoryStateAndPreservesIsolatedStorage() throws {
        let userAUUID = UUID()
        let userAEmail = "alice@example.com"

        // 1. User A logs in and saves a bookmark
        userViewModel.activateCloudAccount(email: userAEmail, uuid: userAUUID) {}
        let book = Book(title: "Alice In Wonderland", ratingsAverage: 4.9, ratingsCount: 100, authorName: ["Lewis Carroll"], coverI: 12, image: nil)
        persistence.saveBook(book, imageData: nil)

        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 1)
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.first?.title, "Alice In Wonderland")

        // 2. User A signs out
        userViewModel.clearCloudAccount()
        bookmarkViewModel.loadBookmarks()

        // In-memory state must be empty
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 0, "Signing out must isolate and evict user bookmarks from active view state")
        XCTAssertNil(userViewModel.currentUserUUID)
        XCTAssertNil(UserDefaults.standard.string(forKey: "LoggedInUserEmail"))

        // 3. User B signs in - must NOT see Alice's bookmarks
        let userBUUID = UUID()
        userViewModel.activateCloudAccount(email: "bob@example.com", uuid: userBUUID) {}
        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 0, "User B must not have access to User A's bookmarks")

        // 4. User A logs back in - their bookmarks remain intact and isolated
        userViewModel.activateCloudAccount(email: userAEmail, uuid: userAUUID) {}
        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 1)
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.first?.title, "Alice In Wonderland")
    }

    // MARK: - Multi-threaded Concurrency & Context Safety

    func testConcurrentBookmarkPersistenceDoesNotCorruptContext() throws {
        let stableUUID = UUID()
        userViewModel.activateCloudAccount(email: "concurrent@example.com", uuid: stableUUID) {}

        let expectation = expectation(description: "Concurrent persistence operations")
        expectation.expectedFulfillmentCount = 10

        let titles = (1...10).map { "Concurrent Volume \($0)" }

        DispatchQueue.concurrentPerform(iterations: 10) { index in
            let b = Book(
                title: titles[index],
                ratingsAverage: 4.0,
                ratingsCount: 10,
                authorName: ["Author \(index)"],
                coverI: index,
                image: nil
            )
            self.persistence.saveBook(b, imageData: nil)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        bookmarkViewModel.loadBookmarks()
        XCTAssertEqual(bookmarkViewModel.bookmarkBooks.count, 10, "All 10 concurrent writes must safely persist without data loss or crashes")
    }

    // MARK: - Demonstrated Failure & Regression Contract

    func testForeignUUIDBookmarksAreRejectedByActiveSession() throws {
        let activeUUID = UUID()
        let attackerUUID = UUID()

        userViewModel.activateCloudAccount(email: "victim@example.com", uuid: activeUUID) {}

        // Manually inject a record with a foreign UUID into Core Data
        let context = persistence.container.viewContext
        guard let foreignEntity = NSEntityDescription.insertNewObject(forEntityName: "BookEntity", into: context) as? BookEntity else {
            XCTFail("Failed to create entity")
            return
        }
        foreignEntity.title = "Injected Book"
        foreignEntity.userUUID = attackerUUID
        foreignEntity.email = "attacker@example.com"
        try context.save()

        // Active session load
        bookmarkViewModel.loadBookmarks()
        let activeTitles = bookmarkViewModel.bookmarkBooks.map(\.title)

        XCTAssertFalse(activeTitles.contains("Injected Book"), "Regression: Active session must strictly filter out entities belonging to other user UUIDs")
    }
}
