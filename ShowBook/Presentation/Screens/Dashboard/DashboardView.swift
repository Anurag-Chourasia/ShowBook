//
//  DashboardView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import LocalizationKit
import CoreData
import UIComponentsKit
import DesignTokensKit
#if DEBUG
import DeveloperProfileKit
#endif

@MainActor
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    init(viewModel: @autoclosure @escaping () -> DashboardViewModel = DashboardViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
                ZStack {
                    VStack(spacing: \.zero) {
                        searchField
                        ZStack {
                            if !viewModel.filteredBooks.isEmpty {
                                VStack{
                                    sortByFilterView
                                    booksListView
                                }
                            }
                            
                            if viewModel.filteredBooks.isEmpty && !viewModel.isBookLoading {
                                if viewModel.searchBook.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && AppRuntime.discoverEnabled {
                                    DiscoverView()
                                } else { searchStateBanner }
                            }
                            if viewModel.isBookLoading {
                                bookLoadingIndicator
                            }
                        }
                        Spacer()
                    }
                    .navigationTitle("ShowBook")
                    .showBookTools(onLogout: { viewModel.logOutAlert = true })
                    .navigationBarTitleDisplayMode(.inline)
                    .alert(isPresented: $viewModel.showAlert) {
                        Alert(title: Text(String(\ShowBookStrings.alertError)),
                              message: Text(viewModel.errorMessage),
                              dismissButton: .default(Text(String(\CommonStrings.ok))) {
                            viewModel.isLoading = false
                        })
                    }
                    .alert(isPresented: $viewModel.logOutAlert) {
                        Alert(
                            title: Text(String(\ShowBookStrings.logout)),
                            message: Text(String(\ShowBookStrings.logoutConfirmationTitle)),
                            primaryButton: .default(Text(String(\ShowBookStrings.actionYes))) {
                                userViewModel.logout()
                            },
                            secondaryButton: .cancel(Text(String(\CommonStrings.cancel))) {
                                viewModel.isLoading = false
                            }
                        )
                    }
                    if viewModel.isLoading {
                        loadingIndicator
                    }
                }
        }
    }
    
    private var searchStateBanner: some View {
        ScrollView {
            SurfaceCard {
                StateMessage {
                    Image(viewModel.searchState == .failed ? \.wifiExclamationmark : \.magnifyingglass)
                } title: {
                    Text(searchStateTitle).multilineTextAlignment(.center)
                } detail: {
                    Text(searchStateDetail)
                } actions: {
                    if viewModel.searchState == .failed {
                        Button(String(\ShowBookStrings.actionRetry)) { viewModel.performSearch() }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(\.twenty)
            .accessibilityIdentifier(.searchStateBanner)
        }
    }

    private var searchStateTitle: String {
        switch viewModel.searchState {
        case .empty: return String(\ShowBookStrings.searchNoBooksFound)
        case .failed: return String(\ShowBookStrings.searchUnableToSearch)
        case .tooShort: return String(\ShowBookStrings.searchKeepTyping)
        default: return String(\ShowBookStrings.searchStartSearching)
        }
    }

    private var searchStateDetail: String {
        switch viewModel.searchState {
        case .empty: return String(format: String(\ShowBookStrings.searchNoMatches), locale: LocalizationController.shared.locale, viewModel.searchBook)
        case .failed: return String(\ShowBookStrings.searchConnectionError)
        default: return String(\ShowBookStrings.searchMinimumCharacters)
        }
    }

    private var searchField: some View {
        HStack {
            Image(\.bookFill)
                .resizable()
                .frame(width: \.p21, height: \.p21)
                .padding([.top, .bottom], \.sixteen)
                .padding([.leading, .trailing], \.p19)
            TextFieldWithDebounce(debouncedText: $viewModel.searchBook)
                .onDisappear { viewModel.cancelRequests() }
                .onChange(of: userViewModel.isLoggedIn) {
                    if !userViewModel.isLoggedIn { viewModel.cancelRequests() }
                }
                .onChange(of: viewModel.searchBook) {
                    viewModel.performSearch()
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignMetricTheme.default.p26_5)
                .stroke(ColorTheme.default.secondary, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, \.fourteen)
        .padding(.horizontal, \.twenty)
    }
    
    private func localizedSortTitle(_ value: String) -> String {
        switch value {
        case "Title": String(\ShowBookStrings.discoverSortTitle)
        case "Average": String(\ShowBookStrings.discoverSortAverage)
        case "Hits": String(\ShowBookStrings.discoverSortHits)
        default: value
        }
    }

    private var sortByFilterView: some View {
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
                    Button(String(\ShowBookStrings.actionClear), role: .destructive) { viewModel.selectedCategoryFilter = "" }
                }
            } label: {
                Label(viewModel.selectedCategoryFilter.isEmpty ? String(\ShowBookStrings.sortBy) : localizedSortTitle(viewModel.selectedCategoryFilter),
                      systemImage: \.arrowUpArrowDown)
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

    private var booksListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: \.zero) {
                BookCollection(books: viewModel.filteredBooks) {
                    viewModel.loadMoreBooksIfNeeded {}
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(\.sixteen)
                } else if !viewModel.loadingMoreBookNotPossible {
                    HStack {
                        Text(String(\ShowBookStrings.loadingMore))
                            .padding(\.sixteen)
                            .foregroundColor(\.primary)
                    }
                }
            }
            .padding(.vertical, \.ten)
        }
    }
    
    
    
    private var loadingIndicator: some View {
        GeometryReader { innerGeometry in
            CenteredProgressOverlay(width: innerGeometry.size.width) {
                Text(String(\ShowBookStrings.loadingProgress))
            } background: {
                ColorTheme.default.groupedSecondary.opacity(OpacityTheme.default.p0_5)
            }
        }
    }
    
    private var bookLoadingIndicator: some View {
        GeometryReader { innerGeometry in
            CenteredProgressOverlay(width: innerGeometry.size.width) {
                Text(String(\ShowBookStrings.loadingProgress))
            } background: {
                ColorTheme.default.groupedSecondary.opacity(OpacityTheme.default.p0_5)
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UserViewModel())
    }
}

#if DEBUG
struct ShowBookDeveloperView: View {
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue

    var body: some View {
        DeveloperProfileView(app: DeveloperAppInfo(
            name: "ShowBook",
            version: AppRuntime.version,
            build: AppRuntime.build,
            disclaimer: "ShowBook is a book discovery application. Book metadata and covers are provided by Open Library. Availability and accuracy depend on the source records.\n\nSource: https://openlibrary.org\n\n[Privacy Policy](https://github.com/Anurag-Chourasia/ShowBook/blob/main/Docs/PrivacyInventory.md) • [Support](mailto:anuragchourasiaios@gmail.com)"
        ), layout: CatalogLayout(rawValue: storedLayout) ?? .list)
        .tint(\.blue)
        .navigationTitle(String(\ShowBookStrings.knowYourDeveloper))
        .showBookTools(includeDeveloper: false, includeLayout: true)
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
