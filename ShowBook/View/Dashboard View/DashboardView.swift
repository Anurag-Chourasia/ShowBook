//
//  DashboardView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: DashboardViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        headerView
                        searchField
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
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("ShowBook")
                .font(.title)
                .padding(.leading, 30)
            Spacer()
            NavigationLink(destination: BookmarkView()) {
                Image(systemName: "bookmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 35)
                    .foregroundColor(.black)
            }
            .padding(.trailing, 30)
            .accessibilityIdentifier("bookmarkButton")
            
            Button(action: {
                viewModel.isLoading = true
                viewModel.logOutAlert = true
            }) {
                Image("Logout")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 20)
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "book.fill")
                .resizable()
                .frame(width: 21, height: 21)
                .padding([.top, .bottom], 16)
                .padding([.leading, .trailing], 19)
            TextFieldWithDebounce(debouncedText: $viewModel.searchBook)
                .onChange(of: viewModel.searchBook) {
                    if !viewModel.isBookLoading && !viewModel.isLoadingMore {
                        viewModel.performSearch()
                    }
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 26.5)
                .stroke(Color(UIColor(hex: "#DADADA")), lineWidth: 1)
        )
        .padding(.bottom, 14)
        .padding(.horizontal, 20)
    }
    
    private var sortByFilterView: some View {
        HStack(spacing: 0) {
            VStack {
                Text("Sort by: ")
                    .foregroundColor(Color(UIColor(hex: "#242E3D")))
                    .font(.system(size: 13))
                Color.clear.frame(height: 3)
            }
            Spacer()
            ForEach(viewModel.sortByCategoryArray, id: \.self) { item in
                filterButton(item: item)
            }
            Spacer()
            
            clearButton
            
            
        }
        .frame(height: 31)
        .padding(.bottom, 10)
    }
    
    private func filterButton(item: String) -> some View {
        Button(action: {
            viewModel.selectedCategoryFilter = item
        }) {
            VStack {
                Text(item)
                    .foregroundColor(viewModel.selectedCategoryFilter == item ? .black : .gray)
                    .font(.system(size: 13))
                if viewModel.selectedCategoryFilter == item {
                    Color(UIColor(hex: "#22B6CA"))
                        .frame(height: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 1.5))
                } else {
                    Color.clear.frame(height: 3)
                }
            }
        }
    }
    
    private var clearButton: some View {
        Button(action: {
            viewModel.selectedCategoryFilter = ""
        }) {
            VStack {
                Text("Clear")
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
                Color.clear.frame(height: 3)
            }
        }
    }
    
    private var booksListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredBooks, id: \.self) { book in
                        BookItem(item: book)
                            .padding(.vertical, 5)
                            .id(book.id)
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).maxY) {
                                let screenHeight = UIScreen.main.bounds.height
                                let threshold = screenHeight - 200
                                let contentHeight = geo.frame(in: .global).maxY
                                if contentHeight < threshold {
                                    viewModel.loadMoreBooksIfNeeded()
                                }
                            }
                    }
                )
                if viewModel.isLoadingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if !viewModel.loadingMoreBookNotPossible {
                    HStack {
                        Text("Loading More...")
                            .padding()
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    
    
    private var loadingIndicator: some View {
        GeometryReader { innerGeometry in
            VStack {
                Spacer()
                ProgressView("Loading.")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
            .frame(width: innerGeometry.size.width)
            .background(Color(UIColor(hex: "#FFFFFF")).opacity(0.5))
        }
    }
    
    private var bookLoadingIndicator: some View {
        GeometryReader { innerGeometry in
            VStack {
                Spacer()
                ProgressView("Loading.")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
            .frame(width: innerGeometry.size.width)
            .background(Color(UIColor(hex: "#FFFFFF")).opacity(0.5))
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
