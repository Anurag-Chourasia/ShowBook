import SwiftUI
import LocalizationKit
import DesignTokensKit

struct DashboardSortFilterBar: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        HStack {
            Menu {
                Section {
                    ForEach(viewModel.sortByCategoryArray, id: \.self) { category in
                        Button { viewModel.selectedCategoryFilter = category } label: {
                            if viewModel.selectedCategoryFilter == category {
                                Label(localizedSortTitle(category), systemImage: \.checkmark)
                            } else {
                                Text(localizedSortTitle(category))
                            }
                        }
                    }
                }
                Section {
                    Button(role: .destructive) { viewModel.selectedCategoryFilter = "" } label: {
                        Text(\.actionClear)
                    }
                }
            } label: {
                let sortTitle = viewModel.selectedCategoryFilter.isEmpty
                    ? String(\.sortBy)
                    : localizedSortTitle(viewModel.selectedCategoryFilter)
                Label(sortTitle, systemImage: \.arrowUpArrowDown)
            }
            .tint(\.primary)
            .font(\.subheadline)
            Spacer()
            BookLayoutPicker()
                .font(\.subheadline)
        }
        .padding(.horizontal, \.twenty)
        .padding(.bottom, \.ten)
    }

    private func localizedSortTitle(_ value: String) -> String {
        switch value {
        case "Title": String(\.discoverSortTitle)
        case "Average": String(\.discoverSortAverage)
        case "Hits": String(\.discoverSortHits)
        default: value
        }
    }
}
