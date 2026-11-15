//
//  DeveloperPresetsSectionView.swift
//  ShowBook
//

import SwiftUI
import DesignTokensKit
import LocalizationKit

#if DEBUG
struct DeveloperPresetsSectionView: View {
    @Binding var source: String
    @Binding var scenario: String
    var onContinue: () -> Void

    var body: some View {
        Section(header: Text(\.developerQuickPresets)) {
            Button {
                source = "stub"
                scenario = "showcase"
                onContinue()
            } label: {
                Label(Text(\.developerPresetShowcase), \.sparkles)
            }
            .accessibilityIdentifier(.developerPresetShowcase)

            Button {
                source = "stub"
                scenario = "empty"
                onContinue()
            } label: {
                Label(Text(\.developerPresetEmpty), \.tray)
            }
            .accessibilityIdentifier(.developerPresetEmpty)

            Button {
                source = "stub"
                scenario = "offline"
                onContinue()
            } label: {
                Label(Text(\.developerPresetOffline), \.wifiSlash)
            }
            .accessibilityIdentifier(.developerPresetOffline)

            Button {
                source = "live"
                onContinue()
            } label: {
                Label(Text(\.developerPresetLiveLibrary), \.globe)
            }
            .accessibilityIdentifier(.developerPresetLive)
        }
    }
}

struct DeveloperCacheSectionView: View {
    let cacheSummary: String
    let onPurge: () -> Void

    var body: some View {
        Section(header: Text(\.developerCacheAndOffline)) {
            let value = cacheSummary.isEmpty ? String(\.developerChecking) : cacheSummary
            LabeledContent(String(\.developerDiskCache), value: value)
            Button(role: .destructive, action: onPurge) {
                Text(\.developerPurgeCatalogCache)
            }
            .accessibilityIdentifier(.developerPurgeCache)
        }
    }
}
#endif
