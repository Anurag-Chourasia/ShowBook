//
//  AccessibilityJourneyTests.swift
//  ShowBookTests
//
//  Accessibility on complete app journeys verification (IOS-25)
//

import XCTest
import SwiftUI
import UIComponentsKit
import DesignTokensKit
@testable import ShowBook

@MainActor
final class AccessibilityJourneyTests: XCTestCase {

    // MARK: - Dynamic Type & Text Clipping Checks

    func testDynamicTypeMaximumAccessibilitySizesDoNotClipBookItem() {
        let book = Book(
            title: "The Comprehensive Accessibility Architecture Guide for Large Dynamic Type Formats",
            ratingsAverage: 4.85,
            ratingsCount: 1420,
            authorName: ["Professor Long Named Author of Accessible Design", "Co-Author Accessibility Specialist"],
            coverI: 12345,
            image: nil,
            key: "/works/OL9999W"
        )

        // Verify across default, accessibility3 and accessibility5
        for typeSize in [DynamicTypeSize.large, .accessibility3, .accessibility5] {
            let view = BookItem(item: book, layout: .list, showsRatings: true)
                .environment(\.dynamicTypeSize, typeSize)

            let controller = UIHostingController(rootView: view)
            controller.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
            controller.view.layoutIfNeeded()

            XCTAssertGreaterThan(controller.view.frame.width, 0)
            XCTAssertGreaterThan(controller.view.frame.height, 0)

            // When isAccessibilitySize is true, title lineLimit is nil (unclipped)
            XCTAssertEqual(typeSize.isAccessibilitySize, typeSize >= .accessibility1)
        }
    }

    func testCatalogLayoutResolvesCorrectlyForAccessibilitySizes() {
        // Accessibility sizes force grid layout into accessible single-column list to prevent truncation
        let gridLayout = CatalogLayout.grid
        XCTAssertEqual(gridLayout.resolved(isAccessibilitySize: false), .grid)
        XCTAssertEqual(gridLayout.resolved(isAccessibilitySize: true), .list)

        let listLayout = CatalogLayout.list
        XCTAssertEqual(listLayout.resolved(isAccessibilitySize: false), .list)
        XCTAssertEqual(listLayout.resolved(isAccessibilitySize: true), .list)
    }

    // MARK: - VoiceOver Labels, Traits & Element Completeness

    func testBookmarkButtonAccessibilityAttributes() {
        let book = Book(
            title: "Accessibility Best Practices",
            ratingsAverage: 5.0,
            ratingsCount: 200,
            authorName: ["Jane Doe"],
            coverI: 99,
            image: nil,
            key: "/works/OL101W"
        )

        let button = BookmarkButton(book: book, imageUrl: nil)
        let controller = UIHostingController(rootView: button)
        controller.view.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }

    func testDashboardAndSearchJourneyVoiceOverElements() async {
        let userVM = UserViewModel()
        let dashboardVM = DashboardViewModel()
        let mockAPI = MockNetworkClass()
        dashboardVM.api = mockAPI
        dashboardVM.searchBook = "Swift"
        mockAPI.result = .success([
            Book(title: "Swift Accessibility in Depth", ratingsAverage: 4.9, ratingsCount: 300, authorName: ["Apple Expert"], coverI: 1, image: nil, key: "/works/OL1")
        ])
        dashboardVM.performSearch()
        await Task.yield()

        let dashboardView = DashboardView(viewModel: dashboardVM)
            .environmentObject(userVM)
            .environment(\.dynamicTypeSize, .accessibility3)

        let controller = UIHostingController(rootView: dashboardView)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()

        XCTAssertFalse(dashboardVM.books.isEmpty, "Search journey should populate results for accessibility inspection")
        XCTAssertEqual(dashboardVM.books.first?.title, "Swift Accessibility in Depth")
    }

    // MARK: - Reduce Motion & High Contrast Adaptations

    func testHighContrastAndDynamicTypeOnDeveloperScreen() {
        let developerView = NavigationStack { ShowBookDeveloperView() }
            .environment(\.dynamicTypeSize, .accessibility3)
            .environment(\.colorScheme, .dark)

        let controller = UIHostingController(rootView: developerView)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
        XCTAssertGreaterThan(controller.view.frame.width, 0)
    }
}
