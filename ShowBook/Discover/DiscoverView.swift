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
            VStack(alignment: .leading, spacing: \.sixteen) {
                VStack(alignment: .leading, spacing: \.eight) {
                    Text("Discover").font(\.title).accessibilityAddTraits(.isHeader)
                    Text("Find your next read. Browse a category or search above.")
                        .font(\.body).foregroundColor(\.secondary)
                    Picker("Category", selection: $category) {
                        ForEach(DiscoverCategory.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.menu)
                    .accessibilityIdentifier(.discoverCategory)
                    if let date = model.cachedAt {
                        Text("Saved titles · \(date.formatted(date: .abbreviated, time: .omitted)). Covers may need a connection.")
                            .font(\.caption).foregroundColor(\.secondary)
                    }
                }.padding(.horizontal, \.sixteen)
                if model.loading {
                    ProgressView("Finding books…").frame(maxWidth: .infinity)
                } else if let message = model.message {
                    StateMessage {
                        Image(\.wifiExclamationmark)
                    } title: { Text("Discover is unavailable") }
                    detail: { Text(message) }
                    actions: { Button("Retry") { reload += 1 } }
                    .padding(\.sixteen)
                } else if model.books.isEmpty {
                    Text("No books available in this category yet.")
                        .font(\.body).padding(\.sixteen)
                } else {
                    HStack {
                        Menu {
                            Section {
                                ForEach(["Title", "Average", "Hits"], id: \.self) { option in
                                    Button { sort = option } label: {
                                        if sort == option { Label(option, \.checkmark) }
                                        else { Text(option) }
                                    }
                                }
                            }
                            Section {
                                Button("Clear", role: .destructive) { sort = "" }
                            }
                        } label: {
                            Label(sort.isEmpty ? "Sort by" : sort, \.arrowUpArrowDown)
                        }
                        .accessibilityIdentifier(.discoverSortMenu)
                        Spacer()
                        BookLayoutPicker(selection: $layout)
                    }
                    .font(\.subheadline)
                    .padding(.horizontal, \.sixteen)
                    BookCollection(books: displayedBooks, layoutOverride: layout)
                }
            }.padding(.vertical, \.sixteen)
        }
        .tint(\.primary)
        .accessibilityIdentifier(.discoverScreen)
        .task(id: category) { await model.load(category) }
        .task(id: reload) { if reload > 0 { await model.load(category, refresh: true) } }
        .refreshable { await model.load(category, refresh: true) }
    }
}
