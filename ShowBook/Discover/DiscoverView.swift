import SwiftUI
import DesignTokensKit
import UIComponentsKit

struct DiscoverView: View {
    @StateObject private var model = DiscoverViewModel()
    @State private var category: DiscoverCategory = .fiction
    @State private var reload = 0
    @State private var layout: CatalogLayout = AppRuntime.discoverGrid ? .grid : .list
    @State private var sort = ""

    private var displayedBooks: [Book] {
        switch sort {
        case "Title": return model.books.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case "Average": return model.books.sorted { ($0.availableRating?.average ?? -1) > ($1.availableRating?.average ?? -1) }
        case "Hits": return model.books.sorted { ($0.ratingsCount ?? -1) > ($1.ratingsCount ?? -1) }
        default: return model.books
        }
    }

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
                    HStack {
                        Menu {
                            Section {
                                ForEach(["Title", "Average", "Hits"], id: \.self) { option in
                                    Button { sort = option } label: {
                                        if sort == option { Label(option, systemImage: "checkmark") }
                                        else { Text(option) }
                                    }
                                }
                            }
                            Section {
                                Button("Clear", role: .destructive) { sort = "" }
                            }
                        } label: {
                            Label(sort.isEmpty ? "Sort by" : sort, systemImage: "arrow.up.arrow.down")
                        }
                        .accessibilityIdentifier("discover-sort-menu")
                        Spacer()
                        BookLayoutPicker(selection: $layout)
                    }
                    .font(Typography.subheadline)
                    .padding(.horizontal, Spacing.sixteen)
                    BookCollection(books: displayedBooks, layoutOverride: layout)
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
