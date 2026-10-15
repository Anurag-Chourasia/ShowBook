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

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: DashboardViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationView {
                ZStack {
                    VStack(spacing: DesignMetric.p0) {
                        headerView
                        searchField
                        HStack { Spacer(); BookLayoutPicker() }
                            .padding(.horizontal, Spacing.twenty)
                        ZStack {
                            if !viewModel.filteredBooks.isEmpty {
                                VStack{
                                    sortByFilterView
                                    booksListView
                                }
                            }
                            
                            if viewModel.isBookLoading {
                                bookLoadingIndicator
                            }
                        }
                        Spacer()
                    }
                    .navigationBarBackButtonHidden()
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
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("ShowBook")
                .font(Typography.title)
                .padding(.leading, Spacing.thirty)
            Spacer()
            NavigationLink(destination: BookmarkView()) {
                Image(systemName: "bookmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: DesignMetric.p35)
                    .foregroundColor(DesignColor.black)
            }
            .padding(.trailing, Spacing.thirty)
            .accessibilityIdentifier("bookmarkButton")
            
            Button(action: {
                viewModel.isLoading = true
                viewModel.logOutAlert = true
            }) {
                Image("Logout")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: DesignMetric.p30)
            }
            .padding(.trailing, Spacing.twenty)
        }
        .padding(.vertical, Spacing.twenty)
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
                            .foregroundColor(DesignColor.black)
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
            .navigationViewStyle(StackNavigationViewStyle())
    }
}
