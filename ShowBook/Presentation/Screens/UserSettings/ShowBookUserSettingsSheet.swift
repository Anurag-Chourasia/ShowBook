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
                disclaimerText: String(\ShowBookStrings.profileDisclaimer),
                developerProfileTitle: String(\ShowBookStrings.knowYourDeveloper)
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
        ) {
            #if DEBUG
            ShowBookDeveloperProfileContainer()
            #else
            EmptyView()
            #endif
        }
    }
}

#if DEBUG
private struct ShowBookDeveloperProfileContainer: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ShowBookDeveloperView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: { Image(\.close) }
                            .accessibilityLabel(\.developerCloseProfile)
                    }
                }
        }
    }
}
#endif
