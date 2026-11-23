import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit
#if DEBUG
import DeveloperProfileKit

struct ShowBookDeveloperView: View {
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue

    var body: some View {
        let disclaimer = "ShowBook is a book discovery application. Book metadata and covers are provided by "
            + "Open Library. Availability and accuracy depend on the source records.\n\n"
            + "Source: https://openlibrary.org\n\n"
            + "[Privacy Policy](https://github.com/Anurag-Chourasia/ShowBook/blob/main/Docs/PrivacyInventory.md)"
            + " • [Support](mailto:anuragchourasiaios@gmail.com)"
        DeveloperProfileView(app: DeveloperAppInfo(
            name: "ShowBook",
            version: AppRuntime.version,
            build: AppRuntime.build,
            disclaimer: disclaimer
        ), layout: CatalogLayout(rawValue: storedLayout) ?? .list)
        .tint(\.blue)
        .background(\.background)
        .navigationTitle(\.knowYourDeveloper)
        .showBookTools(includeDeveloper: false, includeLayout: true)
        .navigationBarTitleDisplayMode(.inline)
        #if os(iOS)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(BrandPalette.current.background, for: .navigationBar)
        #endif
        .applySheetPresentationBackground()
    }
}

private extension View {
    @ViewBuilder
    func applySheetPresentationBackground() -> some View {
        #if os(iOS)
        if #available(iOS 16.4, *) {
            self
                .presentationBackground(BrandPalette.current.background)
                .presentationDragIndicator(.visible)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
#endif
