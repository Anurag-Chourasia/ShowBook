import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

struct DiscoverView: View {
    @StateObject private var model: DiscoverViewModel
    @State private var category: DiscoverCategory = .fiction
    @State private var reload = 0
    @State private var layout: CatalogLayout = AppRuntime.discoverGrid ? .grid : .list
    @State private var sort = ""

    init(model: DiscoverViewModel? = nil) {
        _model = StateObject(wrappedValue: model ?? DiscoverViewModel())
    }

    private func sortTitle(_ value: String) -> String {
        switch value {
        case "Title": String(\ShowBookStrings.discoverSortTitle)
        case "Average": String(\ShowBookStrings.discoverSortAverage)
        case "Hits": String(\ShowBookStrings.discoverSortHits)
        default: value
        }
    }

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
                    Text(String(\ShowBookStrings.discover)).font(\.title).accessibilityAddTraits(.isHeader)
                    Text(String(\ShowBookStrings.discoverSubtitle))
                        .font(\.body).foregroundColor(\.secondary)
                    Picker(String(\ShowBookStrings.discoverCategory), selection: $category) {
                        ForEach(DiscoverCategory.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.menu)
                    .accessibilityIdentifier(.discoverCategory)
                    if let date = model.cachedAt {
                        Text(String(format: String(\ShowBookStrings.discoverCached), locale: LocalizationController.shared.locale, date.formatted(.dateTime.year().month().day().locale(LocalizationController.shared.locale))))
                            .font(\.caption).foregroundColor(\.secondary)
                    }
                }.padding(.horizontal, \.sixteen)
                if model.loading {
                    ProgressView(String(\ShowBookStrings.discoverFinding)).frame(maxWidth: .infinity)
                } else if let message = model.message {
                    StateMessage {
                        Image(\.wifiExclamationmark)
                    } title: { Text(String(\ShowBookStrings.discoverUnavailable)) }
                    detail: { Text(message) }
                    actions: { Button(String(\CommonStrings.retry)) { reload += 1 } }
                    .padding(\.sixteen)
                } else if model.books.isEmpty {
                    Text(String(\ShowBookStrings.noBooksCategory))
                        .font(\.body).padding(\.sixteen)
                } else {
                    HStack {
                        Menu {
                            Section {
                                ForEach(["Title", "Average", "Hits"], id: \.self) { option in
                                    Button { sort = option } label: {
                                        if sort == option { Label(sortTitle(option), \.checkmark) } else { Text(sortTitle(option)) }
                                    }
                                }
                            }
                            Section {
                                Button(String(\ShowBookStrings.actionClear), role: .destructive) { sort = "" }
                            }
                        } label: {
                            Label(sort.isEmpty ? String(\ShowBookStrings.sortBy) : sortTitle(sort), \.arrowUpArrowDown)
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

private extension DiscoverCategory {
    var title: String { LocalizedContext<ShowBookDomain>.shared.string("showbook.category." + rawValue) }
}
