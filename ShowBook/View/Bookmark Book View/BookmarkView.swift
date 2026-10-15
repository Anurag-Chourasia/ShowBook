//
//  BookmarkView.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import CoreData
import UIComponentsKit
import DesignTokensKit

struct BookmarkView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var viewModel = BookmarkViewModel()
    
    var body: some View {
        VStack(spacing: DesignMetric.p0) {
            headerView
            ZStack{
                booksListView
                    .onAppear {
                        viewModel.loadBookmarks()
                    }
                    .onReceive(viewModel.persistenceController.$updatedBooks) { _ in
                        viewModel.bookmarkBooks = viewModel.persistenceController.fetchBooks()
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
        HStack(spacing: DesignMetric.p0) {
            backButton
            Text("Saved Books")
                .font(Typography.title)
            Spacer()
            BookLayoutPicker()
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
        .padding(.trailing, Spacing.system)
    }
    
    private var booksListView: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignMetric.p0) {
                    BookCollection(books: viewModel.bookmarkBooks)
                }
                .padding(.vertical, Spacing.ten)
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

#Preview {
    BookmarkView()
        .navigationViewStyle(StackNavigationViewStyle())
}
