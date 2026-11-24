import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

struct DiscoverView: View {
    @StateObject private var model: DiscoverViewModel
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var category: DiscoverCategory = .fiction
    @State private var reload = 0
    @State private var layout: CatalogLayout = AppRuntime.discoverGrid ? .grid : .list
    @State private var sort: DiscoverSortOption? = nil

    init(model: DiscoverViewModel? = nil) {
        _model = StateObject(wrappedValue: model ?? DiscoverViewModel())
    }

    private var displayedBooks: [Book] { sort?.sort(model.books) ?? model.books }
    private var isOffline: Bool { !networkMonitor.isConnected || model.message != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: \.sixteen) {
                if isOffline {
                    OfflineBannerView(messageKeyPath: \.offlineMessage)
                        .padding(.horizontal, \.sixteen)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                categoryHeader
                if model.loading && model.books.isEmpty {
                    ProgressView { Text(\.discoverFinding) }.frame(maxWidth: .infinity)
                } else if isOffline && model.books.isEmpty {
                    StateMessage {
                        Image(\.wifiSlash)
                    } title: { Text(\.offline) }
                    detail: { Text(\.offlineMessage) }
                    actions: { Button(\.retry) { reload += 1 } }
                    .padding(.horizontal, \.sixteen)
                } else if model.books.isEmpty {
                    Text(\.noBooksCategory).font(\.body).padding(.horizontal, \.sixteen)
                } else {
                    sortAndCatalogView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, \.sixteen)
        }
        .tint(\.primary).accessibilityIdentifier(.discoverScreen)
        .task(id: category) { await model.load(category) }
        .task(id: reload) { if reload > 0 { await model.load(category, refresh: true) } }
        .refreshable { await model.load(category, refresh: true) }
        .onChange(of: networkMonitor.isConnected) { if $0 { reload += 1 } }
    }

    private var categoryHeader: some View {
        VStack(alignment: .leading, spacing: \.eight) {
            Text(\.discover).font(\.title).accessibilityAddTraits(.isHeader)
            Text(\.discoverSubtitle).font(\.body).foregroundColor(\.secondary)
            Picker(selection: $category) {
                ForEach(DiscoverCategory.allCases) { Text($0.titleKeyPath).tag($0) }
            } label: { Text(\.discoverCategory) }
            .pickerStyle(.menu).accessibilityIdentifier(.discoverCategory)
            if let date = model.cachedAt {
                let text = date.formatted(.dateTime.year().month().day().locale(LocalizationController.shared.locale))
                Text(\.discoverCached, arguments: [text]).font(\.caption).foregroundColor(\.secondary)
            }
        }.padding(.horizontal, \.sixteen)
    }

    private var sortAndCatalogView: some View {
        VStack(alignment: .leading, spacing: \.sixteen) {
            HStack {
                Menu {
                    Section {
                        ForEach(DiscoverSortOption.allCases) { opt in
                            Button { sort = opt } label: {
                                if sort == opt { Label(Text(opt.titleKeyPath), \.checkmark) }
                                else { Text(opt.titleKeyPath) }
                            }
                        }
                    }
                    Section { Button(role: .destructive) { sort = nil } label: { Text(\.actionClear) } }
                } label: { Label(sort != nil ? Text(sort!.titleKeyPath) : Text(\.sortBy), \.arrowUpArrowDown) }
                .accessibilityIdentifier(.discoverSortMenu)
                Spacer()
                BookLayoutPicker(selection: $layout)
            }
            .font(\.subheadline).padding(.horizontal, \.sixteen)
            BookCollection(books: displayedBooks, layoutOverride: layout)
        }
    }
}
