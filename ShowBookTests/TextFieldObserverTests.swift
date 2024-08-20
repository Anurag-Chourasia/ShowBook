//
//  TextFieldObserverTests.swift
//  ShowBookTests
//
//  Created by Anurag Chourasia on 18/08/24.
//

import XCTest
import Combine
@testable import ShowBook

class TextFieldObserverTests: XCTestCase {
    var textFieldObserver: TextFieldObserver!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        textFieldObserver = TextFieldObserver()
        cancellables = []
    }

    override func tearDown() {
        textFieldObserver = nil
        cancellables = nil
        super.tearDown()
    }

    func testDebouncedText() {
        let expectation = XCTestExpectation(description: "Debounced text should be updated")

        textFieldObserver.$debouncedText
            .dropFirst() // Ignore the initial value
            .sink { newText in
                XCTAssertEqual(newText, "Hello")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        textFieldObserver.searchText = "H"
        textFieldObserver.searchText = "He"
        textFieldObserver.searchText = "Hel"
        textFieldObserver.searchText = "Hell"
        textFieldObserver.searchText = "Hello"

        wait(for: [expectation], timeout: 1.0)
    }
}
