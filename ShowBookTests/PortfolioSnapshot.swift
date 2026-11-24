import XCTest
import SwiftUI
import UIComponentsKit
import DesignTokensKit
import SnapshotTestKit
@testable import ShowBook

@MainActor
enum PortfolioSnapshot {
    static func assertVariants<V: View>(_ view: V, named name: String,
                                        file: StaticString = #filePath, line: UInt = #line) async throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 snapshot test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }
        for (suffix, style, type) in [
            ("light", UIUserInterfaceStyle.light, DynamicTypeSize.large),
            ("dark", .dark, .large),
            ("accessibility", .light, .accessibility3)
        ] {
            let palette = BrandPalette.palette(for: .showBook)
            let themed = view
                .componentTheme(ComponentTheme(surface: LayoutPreset.compact.card, button: LayoutPreset.compact.button,
                    colors: SemanticColors(palette: palette)))
                .tint(palette.action)
                .transaction { $0.animation = nil; $0.disablesAnimations = true }
                .environment(\.dynamicTypeSize, type)
                .environment(\.colorScheme, style == .dark ? .dark : .light)
            try await Snapshot.assert(themed, named: name + "-" + suffix, style: style, tolerance: 0.005, file: file, line: line)
        }
    }
}
