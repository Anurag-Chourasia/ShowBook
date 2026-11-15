import SwiftUI
import UIComponentsKit
import LocalizationKit
import DesignTokensKit

/// Search and bookmarks share the same saved preference and accessibility fallback.
struct BookLayoutPicker: View {
    var selection: Binding<CatalogLayout>? = nil
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showGridUnavailable = false

    var body: some View {
        let currentLayout = selection?.wrappedValue ?? CatalogLayout(rawValue: storedLayout) ?? .list
        let resolved = currentLayout.resolved(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize)
        CatalogLayoutMenu(
            selection: resolved,
            isAccessibilitySize: dynamicTypeSize.isAccessibilitySize,
            onSelect: { layout in
                if let selection { selection.wrappedValue = layout }
                else { storedLayout = layout.rawValue }
            },
            onGridUnavailable: { showGridUnavailable = true }
        )
        .tint(\.primary)
        .accessibilityIdentifier(.bookLayoutMenu)
        .alert(Text(\.layoutListTitle), isPresented: $showGridUnavailable) {
            Button(\.ok, role: .cancel) {}
        } message: { Text(\.layoutReadability) }
    }
}
