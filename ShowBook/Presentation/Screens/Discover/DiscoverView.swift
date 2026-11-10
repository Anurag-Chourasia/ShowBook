import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

enum DiscoverSortOption: String, CaseIterable, Identifiable {
    case title = "Title"
    case average = "Average"
    case hits = "Hits"

    var id: String { rawValue }

    var titleKeyPath: KeyPath<ShowBookStrings, String> {
        switch self {
        case .title: return \.discoverSortTitle
        case .average: return \.discoverSortAverage
        case .hits: return \.discoverSortHits
        }
    }
}

struct DiscoverView: View {
    @StateObject private var model: DiscoverViewModel
    @State private var category: DiscoverCategory = .fiction
    @State private var reload = 0
    @State private var layout: CatalogLayout = AppRuntime.discoverGrid ? .grid : .list
    @State private var sort: DiscoverSortOption? = nil

    init(model: DiscoverViewModel? = nil) {
        _model = StateObject(wrappedValue: model ?? DiscoverViewModel())
    }

    private var displayedBooks: [Book] {
        guard let sort else { return model.books }
        switch sort {
        case .title: return model.books.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .average: return model.books.sorted { ($0.availableRating?.average ?? -1) > ($1.availableRating?.average ?? -1) }
        case .hits: return model.books.sorted { ($0.ratingsCount ?? -1) > ($1.ratingsCount ?? -1) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: \.sixteen) {
                VStack(alignment: .leading, spacing: \.eight) {
                    Text(\.discover).font(\.title).accessibilityAddTraits(.isHeader)
                    Text(\.discoverSubtitle)
                        .font(\.body).foregroundColor(\.secondary)
                    Picker(selection: $category) {
                        ForEach(DiscoverCategory.allCases) { Text($0.titleKeyPath).tag($0) }
                    } label: {
                        Text(\.discoverCategory)
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier(.discoverCategory)
                    if let date = model.cachedAt {
                        Text(\.discoverCached, arguments: [date.formatted(.dateTime.year().month().day().locale(LocalizationController.shared.locale))])
                            .font(\.caption).foregroundColor(\.secondary)
                    }
                }.padding(.horizontal, \.sixteen)
                if model.loading {
                    ProgressView { Text(\.discoverFinding) }.frame(maxWidth: .infinity)
                } else if let message = model.message {
                    StateMessage {
                        Image(\.wifiExclamationmark)
                    } title: { Text(\.discoverUnavailable) }
                    detail: { Text(message) }
                    actions: { Button(\.retry) { reload += 1 } }
                    .padding(\.sixteen)
                } else if model.books.isEmpty {
                    Text(\.noBooksCategory)
                        .font(\.body).padding(\.sixteen)
                } else {
                    HStack {
                        Menu {
                            Section {
                                ForEach(DiscoverSortOption.allCases) { option in
                                    Button { sort = option } label: {
                                        if sort == option {
                                            Label(Text(option.titleKeyPath), \.checkmark)
                                        } else {
                                            Text(option.titleKeyPath)
                                        }
                                    }
                                }
                            }
                            Section {
                                Button(role: .destructive) { sort = nil } label: {
                                    Text(\.actionClear)
                                }
                            }
                        } label: {
                            if let sort {
                                Label(Text(sort.titleKeyPath), \.arrowUpArrowDown)
                            } else {
                                Label(Text(\.sortBy), \.arrowUpArrowDown)
                            }
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
    var titleKeyPath: KeyPath<ShowBookStrings, String> {
        switch self {
        case .fiction: return \.categoryFiction
        case .mystery: return \.categoryMystery
        case .science: return \.categoryScience
        case .history: return \.categoryHistory
        }
    }
}
