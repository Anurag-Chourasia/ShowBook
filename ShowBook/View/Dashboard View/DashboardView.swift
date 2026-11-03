//
//  DashboardView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import CoreData
import UIComponentsKit
import DesignTokensKit
import DeveloperProfileKit

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
                        Alert(title: Text("Error"),
                              message: Text(viewModel.errorMessage),
                              dismissButton: .default(Text("OK")) {
                            viewModel.isLoading = false
                        })
                    }
                    .alert(isPresented: $viewModel.logOutAlert) {
                        Alert(
                            title: Text("Logout"),
                            message: Text("Are you sure?"),
                            primaryButton: .default(Text("Yes")) {
                                userViewModel.logout()
                            },
                            secondaryButton: .cancel(Text("Cancel")) {
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
                    Image(systemName: viewModel.searchState == .failed ? "wifi.exclamationmark" : "magnifyingglass")
                } title: {
                    Text(searchStateTitle).multilineTextAlignment(.center)
                } detail: {
                    Text(searchStateDetail)
                } actions: {
                    if viewModel.searchState == .failed {
                        Button("Retry") { viewModel.performSearch() }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(\.twenty)
            .accessibilityIdentifier("search-state-banner")
        }
    }

    private var searchStateTitle: String {
        switch viewModel.searchState {
        case .empty: return "No books found"
        case .failed: return "Unable to search"
        case .tooShort: return "Keep typing"
        default: return "Start searching to see books"
        }
    }

    private var searchStateDetail: String {
        switch viewModel.searchState {
        case .empty: return "No matches for “\(viewModel.searchBook)”. Check the spelling or try another book title."
        case .failed: return "We couldn’t load books. Check your connection and try again."
        default: return "Enter at least 3 characters of a book title to begin."
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "book.fill")
                .resizable()
                .frame(width: \.p21, height: \.p21)
                .padding([.top, .bottom], \.sixteen)
                .padding([.leading, .trailing], \.p19)
            TextFieldWithDebounce(debouncedText: $viewModel.searchBook)
                .onChange(of: viewModel.searchBook) {
                    viewModel.performSearch()
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, \.fourteen)
        .padding(.horizontal, \.twenty)
    }
    
    private var sortByFilterView: some View {
        HStack {
            Menu {
                Section {
                    ForEach(viewModel.sortByCategoryArray, id: \.self) { category in
                        Button { viewModel.selectedCategoryFilter = category } label: {
                            if viewModel.selectedCategoryFilter == category {
                                Label(category, systemImage: "checkmark")
                            } else {
                                Text(category)
                            }
                        }
                    }
                }
                Section {
                    Button("Clear", role: .destructive) { viewModel.selectedCategoryFilter = "" }
                }
            } label: {
                Label(viewModel.selectedCategoryFilter.isEmpty ? "Sort by" : viewModel.selectedCategoryFilter,
                      systemImage: "arrow.up.arrow.down")
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
                        Text("Loading More...")
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
                Text("Loading.")
            } background: {
                ShowBookTheme.colors.surface.opacity(OpacityTheme.default.p0_5)
            }
        }
    }
    
    private var bookLoadingIndicator: some View {
        GeometryReader { innerGeometry in
            CenteredProgressOverlay(width: innerGeometry.size.width) {
                Text("Loading.")
            } background: {
                ShowBookTheme.colors.surface.opacity(OpacityTheme.default.p0_5)
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
        .navigationTitle("Know Your Developer")
        .showBookTools(includeDeveloper: false, includeLayout: true)
        .navigationBarTitleDisplayMode(.inline)
    }
}
