//
//  BookmarkView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import UIComponentsKit
import DesignTokensKit

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
        .padding(.vertical, Spacing.twenty)
        .padding(.horizontal, Spacing.twenty)
    }
    
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            OutlinedIconLabel(systemImage: "chevron.left", color: ShowBookTheme.colors.action)
        }
        .padding(.trailing)
    }
    
    private var booksListView: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.bookmarkBooks, id: \.self) { book in
                            BookItem(item: book, fromBookMark: true)
                                .padding(.vertical, Spacing.five)
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
                .padding(.vertical, Spacing.ten)
            }
        }
    
    private var bookLoadingIndicator: some View {
        GeometryReader { innerGeometry in
            CenteredProgressOverlay(width: innerGeometry.size.width) {
                Text("Loading.")
            } background: {
                ShowBookTheme.colors.surface.opacity(0.5)
            }
        }
    }
}

#Preview {
    BookmarkView()
        .navigationViewStyle(StackNavigationViewStyle())
}
