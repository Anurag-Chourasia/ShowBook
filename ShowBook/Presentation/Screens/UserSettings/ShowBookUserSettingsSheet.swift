import SwiftUI
import AuthKit
import AuthKitUI
import DesignTokensKit
import LocalizationKit

struct ShowBookUserSettingsSheet: View {
    @ObservedObject var userViewModel: UserViewModel
    let onDismiss: () -> Void

    var body: some View {
        UserSettingsSheet(
            user: userViewModel.authUser,
            aboutConfiguration: UserSettingsAboutConfiguration(
                appName: String(\ShowBookStrings.appName),
                version: AppRuntime.version,
                build: AppRuntime.build,
                disclaimerTitle: String(\CommonStrings.profileDisclaimer),
                disclaimerText: String(\ShowBookStrings.profileDisclaimer)
            ),
            onSignOut: {
                userViewModel.logout()
                onDismiss()
            },
            onDeleteAccount: {
                userViewModel.deleteAccount()
                onDismiss()
            },
            onDismiss: onDismiss
        )
    }
}
