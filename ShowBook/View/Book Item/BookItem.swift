//
//  BookItem.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import Kingfisher

struct BookItem: View {
    @StateObject private var viewModel: BookItemViewModel
    @State private var isLoading: Bool = true
    
    init(item: Book, fromBookMark: Bool = false) {
        _viewModel = StateObject(wrappedValue: BookItemViewModel(item: item))
        _isLoading = State(initialValue: true)
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                bookImage
                bookDetails
                Spacer()
            }
            .padding(.horizontal, 23)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 15)
                .foregroundColor(Color(UIColor(hex: "#FFFFFF")))
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 0)
                .padding(.horizontal, 13))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        viewModel.onDragChanged(gesture.translation)
                    }
            )
            bookmarkButton
        }
        .onAppear {
            isLoading = !viewModel.isLoading
        }
    }
    
    // MARK: - Book Image
    private var bookImage: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack {
                if let imageUrl = viewModel.imageURL {
                    KFImage.url(imageUrl)
                        .loadDiskFileSynchronously()
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .onProgress { _, _ in
                            isLoading = true
                        }
                        .onSuccess { result in
                            let imageSize = result.image.size
                            isLoading = imageSize.width < 100 || imageSize.height < 100
                        }
                        .onFailure { _ in
                            isLoading = true
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: (CGFloat(100) / 5) * 3, height: 100)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(UIColor(hex: "#22B6CA")), lineWidth: 1)
                            .frame(width: (CGFloat(100) / 5) * 3, height: 100))
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(.white)
                        .frame(width: (CGFloat(100) / 5) * 3, height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(UIColor(hex: "#22B6CA")), lineWidth: 1)
                            .frame(width: (CGFloat(100) / 5) * 3, height: 100))
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .frame(height: 100)
        }
    }
    
    // MARK: - Book Details
    private var bookDetails: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.item.title)
                .font(.footnote)
                .lineLimit(2)
                .foregroundColor(Color(UIColor(hex: "#233C7E")))
                .padding(.bottom, 6)
            
            Text(viewModel.authorNames.isEmpty ? "No Author" : viewModel.authorNames)
                .font(.footnote)
                .lineLimit(2)
                .foregroundColor(Color(UIColor(hex: "#363636")))
                .padding(.bottom, 8)
            
            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    Image(systemName: index < Int(viewModel.item.ratingsAverage ?? 0) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                Text("\(viewModel.item.ratingsCount ?? 0) Ratings")
                    .font(.footnote)
                    .padding(.leading, 10)
            }
            .padding(.bottom, 12)
            
            Text("\((viewModel.item.ratingsAverage ?? 0.0).formattedString(maxFractionDigits: 2)) Average Review")
                .font(.footnote)
                .padding(.bottom, 12)
        }
        .padding(.leading, 17)
    }
    
    // MARK: - Bookmark Button
    private var bookmarkButton: some View {
        Group {
            if viewModel.showBookmarkButton {
                BookmarkButton(book: viewModel.item, imageUrl: viewModel.imageURL)
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing))
            }
        }
    }
}

// Preview
struct BookItem_Previews: PreviewProvider {
    static var previews: some View {
        BookItem(item: Book(title: "HI", ratingsAverage: 3.0, ratingsCount: 5, authorName: ["A"], coverI: 12, image: nil),
                 fromBookMark: false)
    }
}
