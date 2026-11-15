import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

struct ShowBookTools: ViewModifier {
    var includeDeveloper: Bool
    var includeLayout: Bool
    var onLogout: (() -> Void)?
    @Environment(\.persistenceController) private var persistenceController
    @State private var savedPresented = false
    #if DEBUG
    @State private var developerPresented = false
    #endif

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    menuContent
                }
            }
            .navigationDestination(isPresented: $savedPresented) {
                BookmarkView(persistenceController: persistenceController)
            }
            #if DEBUG
            .sheet(isPresented: $developerPresented) {
                NavigationStack {
                    ShowBookDeveloperView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button { developerPresented = false } label: { Image(\.close) }
                                    .accessibilityLabel(\.developerCloseProfile)
                            }
                        }
                }
            }
            #endif
    }

    private var menuContent: some View {
        Menu {
            if onLogout != nil {
                Button { savedPresented = true } label: {
                    Label(Text(\.savedBooks), \.bookmark)
                }
                .accessibilityIdentifier(.bookmarkButton)
            }
            AppearanceMenu(
                title: String(\.appearance),
                systemTitle: String(\ShowBookStrings.appearanceSystem),
                lightTitle: String(\.light),
                darkTitle: String(\.dark)
            )
            if includeLayout { BookLayoutPicker() }
            #if DEBUG
            if includeDeveloper {
                Button { developerPresented = true } label: {
                    Label(Text(\.knowYourDeveloper), \.personCropCircle)
                }
            }
            #endif
            if let onLogout {
                Section {
                    Button(role: .destructive, action: onLogout) {
                        Label(Text(\.logout), \.rectanglePortraitAndArrowRight)
                    }
                }
            }
        } label: { Label(Text(\.appOptions), \.line3Horizontal) }
        .labelStyle(.iconOnly)
        .tint(\.primary)
        .accessibilityIdentifier(.screenTools)
    }
}

extension View {
    func showBookTools(
        includeDeveloper: Bool = true,
        includeLayout: Bool = false,
        onLogout: (() -> Void)? = nil
    ) -> some View {
        modifier(ShowBookTools(includeDeveloper: includeDeveloper, includeLayout: includeLayout, onLogout: onLogout))
    }
}
