//
//  DeveloperSupportSectionView.swift
//  ShowBook
//

import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

#if DEBUG
struct DeveloperSupportSectionView: View {
    @Binding var version: String
    @Binding var build: String
    var onReset: () -> Void

    var body: some View {
        Section(header: Text(\.developerVersionSimulation)) {
            LabeledContent(String(\.developerInstalledVersion), value: AppRuntime.actualVersion)
            LabeledContent(String(\.developerInstalledBuild), value: AppRuntime.actualBuild)
            TextField(String(\.developerSimulatedVersion), text: $version)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField(String(\.developerSimulatedBuild), text: $build)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            Text(\.developerVersionNote)
        }
        Section(header: Text(\.appearance)) {
            AppearanceMenu(
                title: String(\.appearance),
                systemTitle: String(\ShowBookStrings.appearanceSystem),
                lightTitle: String(\.light),
                darkTitle: String(\.dark)
            )
        }
        Section(header: Text(\.developerPrivacySupport)) {
            let privacyURL = "https://github.com/Anurag-Chourasia/ShowBook/blob/main/Docs/PrivacyInventory.md"
            Link(destination: URL(string: privacyURL)!) {
                Label(Text(\.developerPrivacyPolicy), \.handRaised)
            }
            .accessibilityIdentifier(.developerPrivacyPolicy)

            Link(destination: URL(string: "mailto:anuragchourasiaios@gmail.com")!) {
                Label(Text(\.developerSupport), \.envelope)
            }
            .accessibilityIdentifier(.developerSupport)

            Text(\ShowBookStrings.developerPrivacy)
                .font(\.caption)
                .foregroundColor(\.secondary)
        }
        Section {
            Button(role: .destructive, action: onReset) {
                Text(\.developerResetSettings)
            }
            .foregroundColor(\.primary)
        }
    }
}
#endif
