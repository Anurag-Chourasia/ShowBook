import SwiftUI
import DesignTokensKit
import UIComponentsKit

struct DiscoverView: View {
    @StateObject private var model = DiscoverViewModel()
    @State private var category: DiscoverCategory = .fiction
    @State private var reload = 0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sixteen) {
                VStack(alignment: .leading, spacing: Spacing.eight) {
                    Text("Discover").font(Typography.title).accessibilityAddTraits(.isHeader)
                    Text("Find your next read. Browse a category or search above.")
                        .font(Typography.body).foregroundStyle(DesignColor.secondary)
                    Picker("Category", selection: $category) {
                        ForEach(DiscoverCategory.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.menu)
                    .accessibilityIdentifier("discover-category")
                    if let date = model.cachedAt {
                        Text("Saved titles · \(date.formatted(date: .abbreviated, time: .omitted)). Covers may need a connection.")
                            .font(Typography.caption).foregroundStyle(DesignColor.secondary)
                    }
                }.padding(.horizontal, Spacing.sixteen)
                if model.loading {
                    ProgressView("Finding books…").frame(maxWidth: .infinity)
                } else if let message = model.message {
                    StateMessage {
                        Image(systemName: "wifi.exclamationmark")
                    } title: { Text("Discover is unavailable") }
                    detail: { Text(message) }
                    actions: { Button("Retry") { reload += 1 } }
                    .padding(Spacing.sixteen)
                } else if model.books.isEmpty {
                    Text("No books available in this category yet.")
                        .font(Typography.body).padding(Spacing.sixteen)
                } else {
                    BookCollection(books: model.books, layoutOverride: AppRuntime.discoverGrid ? .grid : .list, showsRatings: false)
                }
            }.padding(.vertical, Spacing.sixteen)
        }
        .tint(DesignColor.primary)
        .accessibilityIdentifier("discover-screen")
        .task(id: category) { await model.load(category) }
        .task(id: reload) { if reload > 0 { await model.load(category, refresh: true) } }
        .refreshable { await model.load(category, refresh: true) }
    }
}
