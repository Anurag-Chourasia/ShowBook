//
//  BookmarkView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import LocalizationKit
import CoreData
import UIComponentsKit
import DesignTokensKit

struct BookmarkView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var viewModel = BookmarkViewModel()
    
    var body: some View {
        VStack(spacing: \.zero) {
            ZStack{
                booksListView
                    .onAppear {
                        viewModel.loadBookmarks()
                    }
                    .onReceive(viewModel.persistenceController.$updatedBooks) { _ in
                        viewModel.bookmarkBooks = viewModel.persistenceController.fetchBooks()
                    }
                    .alert(isPresented: $viewModel.showAlert) {
                        Alert(title: Text(String(\ShowBookStrings.alertError)),
                              message: Text(viewModel.errorMessage),
                              dismissButton: .default(Text(String(\CommonStrings.ok))) {
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                if viewModel.isLoading{
                    bookLoadingIndicator
                }
            }
            
        }
        .navigationTitle("Saved Books")
        .navigationBarTitleDisplayMode(.inline)
        .showBookTools(includeLayout: true)
    }
    
    private var booksListView: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: \.zero) {
                    BookCollection(books: viewModel.bookmarkBooks)
                }
                .padding(.vertical, \.ten)
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

#Preview {
    NavigationStack { BookmarkView() }
}
