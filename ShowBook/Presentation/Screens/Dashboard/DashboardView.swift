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
                    .navigationTitle(\ShowBookStrings.appName)
                    .showBookTools(onLogout: { viewModel.logOutAlert = true })
                    .navigationBarTitleDisplayMode(.inline)
                    .alert(isPresented: $viewModel.showAlert) {
                        Alert(title: Text(\.alertError),
                              message: Text(viewModel.errorMessage),
                              dismissButton: .default(Text(\.ok)) {
                            viewModel.isLoading = false
                        })
                    }
                    .alert(isPresented: $viewModel.logOutAlert) {
                        Alert(
                            title: Text(\.logout),
                            message: Text(\.logoutConfirmationTitle),
                            primaryButton: .default(Text(\.actionYes)) {
                                userViewModel.logout()
                            },
                            secondaryButton: .cancel(Text(\.cancel)) {
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
                    searchStateTitleView.multilineTextAlignment(.center)
                } detail: {
                    searchStateDetailView
                } actions: {
                    if viewModel.searchState == .failed {
                        Button(\.actionRetry) { viewModel.performSearch() }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(\.twenty)
            .accessibilityIdentifier(.searchStateBanner)
        }
    }

    @ViewBuilder
    private var searchStateTitleView: some View {
        switch viewModel.searchState {
        case .empty: Text(\.searchNoBooksFound)
        case .failed: Text(\.searchUnableToSearch)
        case .tooShort: Text(\.searchKeepTyping)
        default: Text(\.searchStartSearching)
        }
    }

    @ViewBuilder
    private var searchStateDetailView: some View {
        switch viewModel.searchState {
        case .empty: Text(\.searchNoMatches, arguments: [viewModel.searchBook])
        case .failed: Text(\.searchConnectionError)
        default: Text(\.searchMinimumCharacters)
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
        case "Title": String(\.discoverSortTitle)
        case "Average": String(\.discoverSortAverage)
        case "Hits": String(\.discoverSortHits)
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
                    Button(role: .destructive) { viewModel.selectedCategoryFilter = "" } label: {
                        Text(\.actionClear)
                    }
                }
            } label: {
                Label(viewModel.selectedCategoryFilter.isEmpty ? String(\.sortBy) : localizedSortTitle(viewModel.selectedCategoryFilter),
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
                        Text(\.loadingMore)
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
                Text(\.loadingProgress)
            } background: {
                ColorTheme.default.groupedSecondary.opacity(OpacityTheme.default.p0_5)
            }
        }
    }
    
    private var bookLoadingIndicator: some View {
        GeometryReader { innerGeometry in
            CenteredProgressOverlay(width: innerGeometry.size.width) {
                Text(\.loadingProgress)
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
        .navigationTitle(\.knowYourDeveloper)
        .showBookTools(includeDeveloper: false, includeLayout: true)
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
