import SwiftUI
import LocalizationKit
import DesignTokensKit

struct UserSettingsAccountSection: View {
    let email: String?
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void

    var body: some View {
        Section(String(\CommonStrings.accountTitle)) {
            HStack(spacing: \.twelve) {
                Image(\.personCropCircle)
                    .foregroundStyle(\.secondary)
                Text(email ?? String(\CommonStrings.accountSignedIn))
                    .foregroundStyle(\.primary)
            }

            Button(role: .destructive, action: onSignOut) {
                Label(String(\CommonStrings.authButtonSignOut), \.rectanglePortraitAndArrowRight)
            }

            Button(role: .destructive, action: onDeleteAccount) {
                Label(String(\CommonStrings.authButtonDeleteAccount), \.trash)
            }
        }
    }
}
