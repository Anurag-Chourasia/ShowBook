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
    @EnvironmentObject var viewModel: DashboardViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationStack {
                ZStack {
                    VStack(spacing: DesignMetric.p0) {
                        searchField
                        if !viewModel.filteredBooks.isEmpty {
                            HStack { Spacer(); BookLayoutPicker() }
                                .padding(.horizontal, Spacing.twenty)
                        }
                        ZStack {
                            if !viewModel.filteredBooks.isEmpty {
                                VStack{
                                    sortByFilterView
                                    booksListView
                                }
                            }
                            
                            if viewModel.filteredBooks.isEmpty && !viewModel.isBookLoading {
                                searchStateBanner
                            }
                            if viewModel.isBookLoading {
                                bookLoadingIndicator
                            }
                        }
                        Spacer()
                    }
                    .navigationTitle("ShowBook")
                    .showBookTools()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            NavigationLink(destination: BookmarkView()) {
                                Label("Saved books", systemImage: "bookmark")
                            }
                            .accessibilityIdentifier("bookmarkButton")
                            Button { viewModel.logOutAlert = true } label: {
                                Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    }
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
            .padding(Spacing.twenty)
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
                .frame(width: DesignMetric.p21, height: DesignMetric.p21)
                .padding([.top, .bottom], DesignMetric.p16)
                .padding([.leading, .trailing], DesignMetric.p19)
            TextFieldWithDebounce(debouncedText: $viewModel.searchBook)
                .onChange(of: viewModel.searchBook) {
                    viewModel.performSearch()
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: ShowBookTheme.fieldCornerRadius)
                .stroke(ShowBookTheme.colors.border, lineWidth: StrokeWidth.one)
        )
        .padding(.bottom, Spacing.fourteen)
        .padding(.horizontal, Spacing.twenty)
    }
    
    private var sortByFilterView: some View {
        HStack {
            Menu {
                ForEach(viewModel.sortByCategoryArray, id: \.self) { category in
                    Button(category) { viewModel.selectedCategoryFilter = category }
                }
                Button("Clear") { viewModel.selectedCategoryFilter = "" }
            } label: {
                Label(viewModel.selectedCategoryFilter.isEmpty ? "Sort by" : viewModel.selectedCategoryFilter,
                      systemImage: "arrow.up.arrow.down")
            }
            .font(Typography.subheadline)
            Spacer()
        }
        .padding(.horizontal, Spacing.twenty)
        .padding(.bottom, Spacing.ten)
    }

    private var booksListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: DesignMetric.p0) {
                BookCollection(books: viewModel.filteredBooks) {
                    viewModel.loadMoreBooksIfNeeded {}
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.all, Spacing.system)
                } else if !viewModel.loadingMoreBookNotPossible {
                    HStack {
                        Text("Loading More...")
                            .padding(.all, Spacing.system)
                            .foregroundColor(DesignColor.primary)
                    }
                }
            }
            .padding(.vertical, Spacing.ten)
        }
    }
    
    
    
    private var loadingIndicator: some View {
        GeometryReader { innerGeometry in
            CenteredProgressOverlay(width: innerGeometry.size.width) {
                Text("Loading.")
            } background: {
                ShowBookTheme.colors.surface.opacity(OpacityToken.p0_5)
            }
        }
    }
    
    private var bookLoadingIndicator: some View {
        GeometryReader { innerGeometry in
            CenteredProgressOverlay(width: innerGeometry.size.width) {
                Text("Loading.")
            } background: {
                ShowBookTheme.colors.surface.opacity(OpacityToken.p0_5)
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UserViewModel())
            .environmentObject(DashboardViewModel())
    }
}

struct ShowBookDeveloperView: View {
    @AppStorage("bookCatalogLayout") private var storedLayout = CatalogLayout.list.rawValue

    var body: some View {
        DeveloperProfileView(app: DeveloperAppInfo(
            name: "ShowBook",
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—",
            build: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—",
            disclaimer: "ShowBook is a book discovery application. Book metadata and covers are provided by Open Library. Availability and accuracy depend on the source records.\n\nSource: https://openlibrary.org"
        ), layout: CatalogLayout(rawValue: storedLayout) ?? .list)
        .tint(DesignColor.blue)
        .navigationTitle("Know Your Developer")
        .showBookTools(includeDeveloper: false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { BookLayoutPicker() } }
    }
}
