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
        let runtime = ProcessInfo.processInfo.operatingSystemVersion
        XCTAssertEqual(runtime.majorVersion, 27, file: file, line: line)
        XCTAssertEqual(runtime.minorVersion, 0, file: file, line: line)
        XCTAssertEqual(SnapshotDevice.current, .iPhone11, file: file, line: line)
        for (suffix, style, type) in [
            ("light", UIUserInterfaceStyle.light, DynamicTypeSize.large),
            ("dark", .dark, .large),
            ("accessibility", .light, .accessibility3)
        ] {
            let themed = view
                .componentTheme(ComponentTheme(surface: LayoutPreset.compactMedia.card, button: LayoutPreset.compactMedia.button,
                    colors: SemanticColors(surface: Color("BrandSurface"), foreground: Color("BrandText"),
                        border: Color("BrandBorder"), action: Color("BrandAction"), onAction: Color("BrandOnAction"))))
                .tint(Color("BrandAction"))
                .transaction { $0.animation = nil; $0.disablesAnimations = true }
                .environment(\.dynamicTypeSize, type)
                .environment(\.colorScheme, style == .dark ? .dark : .light)
            try await Snapshot.assert(themed, named: name + "-" + suffix, style: style, tolerance: 0.005, file: file, line: line)
        }
    }
}
