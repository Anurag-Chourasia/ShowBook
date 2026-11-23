import XCTest
import SwiftUI
@testable import ShowBook

@MainActor
final class UserSettingsViewTests: XCTestCase {
    private var persistenceController: PersistenceController!
    private var viewModel: UserViewModel!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController.inMemory()
        viewModel = UserViewModel(persistenceController: persistenceController)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "LoggedInUserEmail")
        UserDefaults.standard.removeObject(forKey: "LoggedInUserUUID")
        viewModel = nil
        persistenceController = nil
        super.tearDown()
    }

    func testUserSettingsViewRendersWithAuthenticatedUser() {
        let uuid = UUID()
        let email = "reader@showbook.example"
        UserDefaults.standard.set(uuid.uuidString, forKey: "LoggedInUserUUID")
        UserDefaults.standard.set(email, forKey: "LoggedInUserEmail")
        viewModel.checkLoginStatus()

        var dismissed = false
        let view = ShowBookUserSettingsSheet(
            userViewModel: viewModel,
            onDismiss: { dismissed = true }
        )

        let hosting = UIHostingController(rootView: view)
        hosting.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hosting.view.layoutIfNeeded()

        XCTAssertNotNil(hosting.view)
        XCTAssertGreaterThan(hosting.view.frame.width, 0)
        XCTAssertFalse(dismissed)
    }

    func testUserSettingsViewRendersInGuestMode() {
        var dismissed = false
        let view = ShowBookUserSettingsSheet(
            userViewModel: viewModel,
            onDismiss: { dismissed = true }
        )

        let hosting = UIHostingController(rootView: view)
        hosting.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hosting.view.layoutIfNeeded()

        XCTAssertNotNil(hosting.view)
        XCTAssertGreaterThan(hosting.view.frame.width, 0)
        XCTAssertFalse(dismissed)
    }

    func testUserSettingsSignOutAndAccountDeletion() {
        let uuid = UUID()
        let email = "reader@showbook.example"
        var signOutCalled = false
        var deleteAccountCalled = false

        viewModel.activateCloudAccount(
            email: email,
            uuid: uuid,
            signOut: { signOutCalled = true },
            deleteAccount: { deleteAccountCalled = true }
        )

        XCTAssertTrue(viewModel.isLoggedIn)
        XCTAssertEqual(viewModel.currentUserEmail, email)
        XCTAssertEqual(viewModel.currentUserUUID, uuid)

        viewModel.deleteAccount()
        XCTAssertTrue(deleteAccountCalled)
        XCTAssertFalse(viewModel.isLoggedIn)
        XCTAssertNil(viewModel.currentUserUUID)
        XCTAssertNil(viewModel.currentUserEmail)

        viewModel.activateCloudAccount(
            email: email,
            uuid: uuid,
            signOut: { signOutCalled = true },
            deleteAccount: { deleteAccountCalled = true }
        )

        viewModel.logout()
        XCTAssertTrue(signOutCalled)
        viewModel.clearCloudAccount()
        XCTAssertFalse(viewModel.isLoggedIn)
        XCTAssertNil(viewModel.currentUserUUID)
        XCTAssertNil(viewModel.currentUserEmail)
    }
}
