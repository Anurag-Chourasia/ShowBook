//
//  DeveloperSettingsView.swift
//  ShowBook
//

import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

#if DEBUG
struct DeveloperSettingsView: View {
    var buttonTitle = String(\ShowBookStrings.applyAndClose)
    var onContinue: () -> Void
    var cacheSummaryOverride: String?
    @AppStorage("developer.authentication") private var authentication = false
    @AppStorage("developer.discover") private var discover = true
    @AppStorage("developer.coverPreview") private var preview = true
    @AppStorage("developer.ratings") private var ratings = true
    @AppStorage("developer.httpLogs") private var logs = ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1"
    @AppStorage("developer.source") private var source = "live"
    @AppStorage("developer.scenario") private var scenario = "success"
    @AppStorage("developer.discoverVariant") private var variant = "A"
    @AppStorage("developer.version") private var version = ""
    @AppStorage("developer.build") private var build = ""
    @State private var cacheSummary = ""

    private let diskCache: BookCatalogCache

    init(
        buttonTitle: String = String(\ShowBookStrings.applyAndClose),
        onContinue: @escaping () -> Void,
        cacheSummaryOverride: String? = nil,
        diskCache: BookCatalogCache = BookCatalogCache()
    ) {
        self.buttonTitle = buttonTitle
        self.onContinue = onContinue
        self.cacheSummaryOverride = cacheSummaryOverride
        self.diskCache = diskCache
    }

    var body: some View {
        Form {
            Section {
                Text(\.developerSettingsSubtitleShowBook)
                Button(buttonTitle, action: onContinue)
                    .foregroundColor(\.primary)
                    .accessibilityIdentifier(.developerOpenApp)
            }
            DeveloperPresetsSectionView(source: $source, scenario: $scenario, onContinue: onContinue)
            DeveloperCacheSectionView(cacheSummary: cacheSummary) {
                diskCache.clear()
                refreshCacheSummary()
            }
            DeveloperFeatureFlagsSectionView(
                authentication: $authentication,
                discover: $discover,
                preview: $preview,
                ratings: $ratings,
                logs: $logs
            )
            DeveloperEnvironmentSectionView(source: $source, scenario: $scenario, variant: $variant)
            DeveloperSupportSectionView(version: $version, build: $build) {
                resetSettings()
            }
        }
        .navigationTitle(Text(\.developerSettingsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .tint(\.primary)
        .toggleStyle(SwitchToggleStyle(tint: DesignColor.green))
        .onAppear(perform: refreshCacheSummary)
    }

    private func resetSettings() {
        authentication = false; discover = true; preview = true; ratings = true; logs = false
        source = "live"; scenario = "success"; variant = "A"
        version = ""; build = ""
    }

    private func refreshCacheSummary() {
        if let cacheSummaryOverride {
            cacheSummary = cacheSummaryOverride
            return
        }
        let count = diskCache.cachedQueriesCount
        if count == 0 {
            cacheSummary = String(\ShowBookStrings.developerCacheEmpty)
        } else {
            cacheSummary = String(\ShowBookStrings.developerCacheSummary, arguments: [count, diskCache.formattedFileSize])
        }
    }
}
#endif
