//
//  DashBoardViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var searchBook: String = ""
    @Published var books: [Book] = []
    @Published var selectedCategoryFilter: String = ""
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var logOutAlert: Bool = false
    @Published var isLoading: Bool = false
    @Published var isBookLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var loadingMoreBookNotPossible: Bool = false
    @Published var scrollOffset: CGFloat = 0
    
    var api = NetworkClass()
    var offset: Int = 0
    private var requestID = UUID()
    private var loadedTitle: String?
    
    var sortByCategoryArray: [String] = ["Title", "Average", "Hits"]
    
    var filteredBooks: [Book] {
        guard searchBook.count >= 3 else {
            return []
        }
        
        switch selectedCategoryFilter {
        case "Title":
            return books.sorted { $0.title < $1.title }
        case "Average":
            return books.sorted { ($0.ratingsAverage ?? 0) > ($1.ratingsAverage ?? 0) }
        case "Hits":
            return books.sorted { ($0.ratingsCount ?? 0) > ($1.ratingsCount ?? 0) }
        default:
            return books
        }
    }
    
    func performSearch() {
        requestID = UUID()
        books = []
        loadedTitle = nil
        offset = 0
        loadingMoreBookNotPossible = false
        showAlert = false
        errorMessage = ""
        isBookLoading = false
        isLoadingMore = false
        guard searchBook.count >= 3 else { return }
        isBookLoading = true
        fetchBooks(title: searchBook, offset: 0) {}
    }

    func fetchBooks(title: String, offset: Int, completion: @escaping () -> Void) {
        let id = UUID()
        requestID = id
        isLoadingMore = true
        api.fetchBooks(title: title, offset: offset) { [weak self] result in
            DispatchQueue.main.async {
                defer { completion() }
                guard let self, self.requestID == id else { return }
                self.isBookLoading = false
                self.isLoadingMore = false
                switch result {
                case .success(let books):
                    self.books = offset == 0 ? books : self.books + books
                    self.offset = offset
                    self.loadedTitle = title
                    self.loadingMoreBookNotPossible = books.isEmpty
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }

    func loadMoreBooksIfNeeded(completion: @escaping () -> Void) {
        guard !isLoadingMore, !isBookLoading, !loadingMoreBookNotPossible,
              let loadedTitle, loadedTitle == searchBook else {
            completion()
            return
        }
        fetchBooks(title: loadedTitle, offset: offset + 10, completion: completion)
    }
}
