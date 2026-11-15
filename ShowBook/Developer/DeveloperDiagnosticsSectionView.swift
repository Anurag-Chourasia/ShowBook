//
//  DeveloperDiagnosticsSectionView.swift
//  ShowBook
//

import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

#if DEBUG
struct DeveloperFeatureFlagsSectionView: View {
    @Binding var authentication: Bool
    @Binding var discover: Bool
    @Binding var preview: Bool
    @Binding var ratings: Bool
    @Binding var logs: Bool

    var body: some View {
        Section(header: Text(\.developerFeatureFlags)) {
            Toggle(isOn: $authentication) { Text(\.developerAuthentication) }
                .accessibilityIdentifier(.developerAuthentication)
            Text(\ShowBookStrings.developerAuthNote)
            Toggle(isOn: $discover) { Text(\.discover) }
            Toggle(isOn: $preview) { Text(\.detailsCoverPreview) }
            Toggle(isOn: $ratings) { Text(\.developerRatings) }
        }
        Section(header: Text(\.developerDebugLogs)) {
            Toggle(isOn: $logs) { Text(\.developerHttpLogs) }
            Text(\.developerLogsNote)
        }
    }
}

struct DeveloperEnvironmentSectionView: View {
    @Binding var source: String
    @Binding var scenario: String
    @Binding var variant: String

    var body: some View {
        Section(header: Text(\.developerEnvironment)) {
            Picker(String(\.developerDataSource), selection: $source) {
                Text(\ShowBookStrings.developerLive).tag("live")
                Text(\CommonStrings.developerSourceStub).tag("stub")
            }
            if source == "stub" {
                Picker(String(\.developerScenario), selection: $scenario) {
                    Text(\.developerPresetShowcase).tag("showcase")
                    Text(\.developerScenarioSuccess).tag("success")
                    Text(\.developerScenarioEmpty).tag("empty")
                    Text(\.developerScenarioOffline).tag("offline")
                }
            }
            Text(\ShowBookStrings.developerStubNote)
        }
        Section(header: Text(\.developerExperiment)) {
            Picker(selection: $variant) {
                Text(\.developerLayoutA).tag("A")
                Text(\.developerLayoutB).tag("B")
            } label: {
                Text(\.developerLayout)
            }
            Text(\.developerExperimentNote)
        }
    }
}
#endif
