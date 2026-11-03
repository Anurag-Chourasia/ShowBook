//
//  BookmarkButton.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import DesignTokensKit

struct BookmarkButton: View {
    @StateObject private var viewModel = BookmarkButtonViewModel()
    var book: Book
    var imageUrl: URL?
    
    var body: some View {
        Button(action: viewModel.toggleBookmark) {
            bookmarkImage
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isBookmarked ? "Remove bookmark" : "Bookmark book")
        .accessibilityValue(book.title)
        .onAppear {
            viewModel.configure(book: book, imageUrl: imageUrl)
        }
    }
    
    private var bookmarkImage: some View {
        Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
            .foregroundColor(viewModel.isBookmarked ? \.white : \.green)
            .padding(\.eight)
            .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
            .background(viewModel.isBookmarked ? \.green : \.groupedSecondary)
            .clipShape(Circle())
            .shadow(radius: DesignMetricTheme.default.p3)
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
