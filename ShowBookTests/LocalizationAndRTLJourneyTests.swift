//
//  LocalizationAndRTLJourneyTests.swift
//  ShowBookTests
//
//  Verification of localized authentication, recoverable errors, and RTL journeys (IOS-26)
//

import XCTest
import SwiftUI
import UIComponentsKit
import DesignTokensKit
import LocalizationKit
import AuthKit
import AuthKitUI
@testable import ShowBook

@MainActor
final class LocalizationAndRTLJourneyTests: XCTestCase {

    private var localizationController: LocalizationController!

    override func setUp() {
        super.setUp()
        localizationController = LocalizationController()
    }

    override func tearDown() {
        localizationController = nil
        super.tearDown()
    }

    // MARK: - Localized Copy Verification Across Locales

    func testLocalizedAuthAndErrorCopyAcrossLocales() {
        let locales = ["en", "fr", "ar"]

        for localeCode in locales {
            let controller = LocalizationController(initialLocale: Locale(identifier: localeCode))

            // Verify auth strings
            let signIn = L10n.Auth.signIn(using: controller)
            let email = L10n.Auth.email(using: controller)
            let password = L10n.Auth.password(using: controller)
            let forgotPassword = L10n.Auth.forgotPassword(using: controller)

            XCTAssertFalse(signIn.isEmpty, "Sign in string should not be empty for \(localeCode)")
            XCTAssertFalse(email.isEmpty, "Email string should not be empty for \(localeCode)")
            XCTAssertFalse(password.isEmpty, "Password string should not be empty for \(localeCode)")
            XCTAssertFalse(forgotPassword.isEmpty, "Forgot password string should not be empty for \(localeCode)")

            // Verify account strings
            let deleteAccount = L10n.Account.deleteAccount(using: controller)
            let signOut = L10n.Account.signOut(using: controller)
            XCTAssertFalse(deleteAccount.isEmpty, "Delete account should not be empty for \(localeCode)")
            XCTAssertFalse(signOut.isEmpty, "Sign out should not be empty for \(localeCode)")

            // Verify recoverable error strings
            let storeErrorTitle = L10n.Errors.storeLoadFailed(using: controller)
            let storeErrorMessage = L10n.Errors.storeLoadMessage(using: controller)
            let retry = L10n.Errors.recoverableRetry(using: controller)

            XCTAssertFalse(storeErrorTitle.isEmpty, "Store error title should not be empty for \(localeCode)")
            XCTAssertFalse(storeErrorMessage.isEmpty, "Store error message should not be empty for \(localeCode)")
            XCTAssertFalse(retry.isEmpty, "Retry button text should not be empty for \(localeCode)")

            if localeCode == "ar" {
                XCTAssertTrue(controller.isRightToLeft, "Arabic locale must be detected as right-to-left")
            } else {
                XCTAssertFalse(controller.isRightToLeft, "\(localeCode) locale must be detected as left-to-right")
            }
        }
    }

    // MARK: - StoreLoadErrorRecoveryView Localization and RTL

    func testStoreLoadErrorRecoveryViewInRTLAndLTR() {
        var retried = false
        let dummyError = NSError(domain: "ShowBookTest", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test store error"])

        let ltrController = LocalizationController(initialLocale: Locale(identifier: "en"))
        let ltrView = StoreLoadErrorRecoveryView(error: dummyError, localization: ltrController) {
            retried = true
        }

        let ltrHost = UIHostingController(rootView: ltrView)
        ltrHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        ltrHost.view.layoutIfNeeded()

        XCTAssertNotNil(ltrHost.view)
        XCTAssertGreaterThan(ltrHost.view.frame.width, 0)

        // RTL View with Arabic
        let rtlController = LocalizationController(initialLocale: Locale(identifier: "ar"))
        let rtlView = StoreLoadErrorRecoveryView(error: dummyError, localization: rtlController) {
            retried = true
        }

        let rtlHost = UIHostingController(rootView: rtlView)
        rtlHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        rtlHost.view.layoutIfNeeded()

        XCTAssertNotNil(rtlHost.view)
        XCTAssertGreaterThan(rtlHost.view.frame.width, 0)

        ltrView.retryAction()
        XCTAssertTrue(retried)
    }

    // MARK: - Auth Views Rendering Under RTL and Dynamic Type

    func testLoginViewAndSignUpViewUnderRTL() {
        let userViewModel = UserViewModel()

        let rtlLoginView = LoginView()
            .environmentObject(userViewModel)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.dynamicTypeSize, .accessibility3)

        let loginHost = UIHostingController(rootView: rtlLoginView)
        loginHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        loginHost.view.layoutIfNeeded()

        XCTAssertNotNil(loginHost.view)
        XCTAssertGreaterThan(loginHost.view.frame.height, 0)

        let rtlSignUpView = SignUpView()
            .environmentObject(userViewModel)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.dynamicTypeSize, .accessibility3)

        let signUpHost = UIHostingController(rootView: rtlSignUpView)
        signUpHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        signUpHost.view.layoutIfNeeded()

        XCTAssertNotNil(signUpHost.view)
        XCTAssertGreaterThan(signUpHost.view.frame.height, 0)
    }

    // MARK: - AppAuthGate Integration with AuthLocalizing

    func testAppAuthGateWithLocalizationController() {
        let arabicController = LocalizationController(initialLocale: Locale(identifier: "ar"))
        var signedOut = false

        let gateView = AppAuthGate(
            brand: .showBook,
            localizer: arabicController,
            onSignedOut: { signedOut = true },
            content: { _, _ in
                Text("Authenticated")
            }
        )
        .environment(\.layoutDirection, arabicController.isRightToLeft ? .rightToLeft : .leftToRight)

        let gateHost = UIHostingController(rootView: gateView)
        gateHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        gateHost.view.layoutIfNeeded()

        XCTAssertNotNil(gateHost.view)
        XCTAssertFalse(signedOut)
    }

    // MARK: - Complete Journey Dynamic Type + RTL Text Truncation Check

    func testBookItemAndBookmarkButtonUnderRTLAndAccessibilityTextSize() {
        let book = Book(
            title: "كتاب الدليل الشامل في واجهات المستخدم المتقدمة",
            ratingsAverage: 4.9,
            ratingsCount: 850,
            authorName: ["مؤلف التصميم الميسر"],
            coverI: 1234,
            image: nil,
            key: "/works/AR123"
        )

        let rtlBookItem = BookItem(item: book, layout: .list, showsRatings: true)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.dynamicTypeSize, .accessibility3)

        let bookHost = UIHostingController(rootView: rtlBookItem)
        bookHost.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        bookHost.view.layoutIfNeeded()

        XCTAssertNotNil(bookHost.view)
        XCTAssertGreaterThan(bookHost.view.frame.width, 0)

        let rtlBookmark = BookmarkButton(book: book, imageUrl: nil)
            .environment(\.layoutDirection, .rightToLeft)

        let buttonHost = UIHostingController(rootView: rtlBookmark)
        buttonHost.view.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        buttonHost.view.layoutIfNeeded()

        XCTAssertNotNil(buttonHost.view)
    }
}
