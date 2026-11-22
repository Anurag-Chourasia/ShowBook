import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

struct UserSettingsView: View {
    @ObservedObject var userViewModel: UserViewModel
    let onDismiss: () -> Void

    @State private var showingDeleteConfirmation = false
    #if DEBUG
    @State private var showingDeveloperProfile = false
    #endif

    var body: some View {
        NavigationStack {
            Form {
                UserSettingsAccountSection(
                    email: userViewModel.currentUserEmail,
                    onSignOut: {
                        userViewModel.logout()
                        onDismiss()
                    },
                    onDeleteAccount: {
                        showingDeleteConfirmation = true
                    }
                )

                #if DEBUG
                UserSettingsAboutSection(
                    appName: String(\ShowBookStrings.appName),
                    version: AppRuntime.version,
                    build: AppRuntime.build,
                    disclaimerText: String(\ShowBookStrings.profileDisclaimer),
                    onOpenDeveloperProfile: {
                        showingDeveloperProfile = true
                    }
                )
                #else
                UserSettingsAboutSection(
                    appName: String(\ShowBookStrings.appName),
                    version: AppRuntime.version,
                    build: AppRuntime.build,
                    disclaimerText: String(\ShowBookStrings.profileDisclaimer),
                    onOpenDeveloperProfile: nil
                )
                #endif
            }
            .navigationTitle(String(\CommonStrings.accountTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(\CommonStrings.done)) {
                        onDismiss()
                    }
                }
            }
            .confirmationDialog(
                String(\CommonStrings.accountDeleteConfirmationTitle),
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(\CommonStrings.accountDeleteConfirmationAction), role: .destructive) {
                    userViewModel.deleteAccount()
                    onDismiss()
                }
                Button(String(\CommonStrings.cancel), role: .cancel) {}
            } message: {
                Text(String(\CommonStrings.accountDeleteConfirmationMessage))
            }
            #if DEBUG
            .sheet(isPresented: $showingDeveloperProfile) {
                NavigationStack {
                    ShowBookDeveloperView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    showingDeveloperProfile = false
                                } label: {
                                    Image(\.close)
                                }
                                .accessibilityLabel(\.developerCloseProfile)
                            }
                        }
                }
            }
            #endif
        }
    }
}
