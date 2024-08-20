//
//  BookmarkButton.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI

struct BookmarkButton: View {
    @StateObject private var viewModel = BookmarkButtonViewModel()
    var book: Book
    var imageUrl: URL?
    
    var body: some View {
        Button(action: viewModel.toggleBookmark) {
            bookmarkImage
        }
        .onAppear {
            viewModel.configure(book: book, imageUrl: imageUrl)
        }
    }
    
    private var bookmarkImage: some View {
        Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
            .foregroundColor(viewModel.isBookmarked ? .white : .green)
            .padding(8)
            .background(viewModel.isBookmarked ? Color.green : .white)
            .clipShape(Circle())
            .shadow(radius: 3)
    }
}

#Preview {
    BookmarkButton(
        book: Book(
            title: "Sample Book Title",
            ratingsAverage: 4.5,
            ratingsCount: 123,
            authorName: ["Author Name"],
            coverI: 12345,
            image: nil
        ),
        imageUrl: nil
    )
}
