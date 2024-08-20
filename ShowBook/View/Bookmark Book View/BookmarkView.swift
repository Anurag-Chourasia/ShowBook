//
//  BookmarkView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI

struct BookmarkView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var viewModel = BookmarkViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            ZStack{
                booksListView
                    .onAppear {
                        viewModel.loadBookmarks()
                    }
                    .alert(isPresented: $viewModel.showAlert) {
                        Alert(title: Text("Error"),
                              message: Text(viewModel.errorMessage),
                              dismissButton: .default(Text("OK")) {
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                if viewModel.isLoading{
                    bookLoadingIndicator
                }
            }
            
        }
        .navigationBarBackButtonHidden()
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var headerView: some View {
        HStack(spacing: 0) {
            backButton
            Text("Saved Books")
                .font(.title)
            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
    }
    
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 15, height: 15)
                .padding()
                .foregroundStyle(Color(UIColor(hex: "#07629B")))
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(UIColor(hex: "#07629B")), lineWidth: 2)
                )
        }
        .padding(.trailing)
    }
    
    private var booksListView: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.bookmarkBooks, id: \.self) { book in
                            BookItem(item: book, fromBookMark: true)
                                .padding(.vertical, 5)
                                .id(book.id)
                        }
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global).minY) {
                                    if geo.frame(in: .global).minY > 0 {
                                        viewModel.loadBookmarks()
                                    }
                                }
                        }
                    )
                }
                .padding(.vertical, 10)
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

#Preview {
    BookmarkView()
        .navigationViewStyle(StackNavigationViewStyle())
}
