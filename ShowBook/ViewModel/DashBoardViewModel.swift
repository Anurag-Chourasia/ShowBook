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
    var cache: BookCatalogCache = .shared
    var offset: Int = 0
    private var requestID = UUID()
    private var requestTask: Task<Void, Never>?

    deinit { requestTask?.cancel() }

    func cancelRequests() {
        requestTask?.cancel()
        requestTask = nil
        requestID = UUID()
        isBookLoading = false
        isLoadingMore = false
    }
    private var loadedTitle: String?

    private struct FilterCache {
        let query: String
        let filter: String
        let books: [Book]
        let result: [Book]
    }
    private var filterCache: FilterCache?

    enum SearchState: Equatable { case idle, tooShort, loading, results, empty, failed }
    var searchState: SearchState {
        let query = searchBook.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return .idle }
        if query.count < 3 { return .tooShort }
        if isBookLoading { return .loading }
        if !books.isEmpty { return .results }
        if !errorMessage.isEmpty { return .failed }
        return loadedTitle == searchBook ? .empty : .idle
    }

    var sortByCategoryArray: [String] = ["Title", "Average", "Hits"]

    var filteredBooks: [Book] {
        let query = searchBook.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else {
            return []
        }

        if let cache = filterCache,
           cache.query == query,
           cache.filter == selectedCategoryFilter,
           cache.books == books {
            return cache.result
        }

        let sorted: [Book]
        switch selectedCategoryFilter {
        case "Title":
            sorted = books.sorted { $0.title < $1.title }
        case "Average":
            sorted = books.sorted { ($0.ratingsAverage ?? 0) > ($1.ratingsAverage ?? 0) }
        case "Hits":
            sorted = books.sorted { ($0.ratingsCount ?? 0) > ($1.ratingsCount ?? 0) }
        default:
            sorted = books
        }

        filterCache = FilterCache(
            query: query,
            filter: selectedCategoryFilter,
            books: books,
            result: sorted
        )
        return sorted
    }

    func performSearch() {
        cancelRequests()
        books = []
        loadedTitle = nil
        offset = 0
        loadingMoreBookNotPossible = false
        showAlert = false
        errorMessage = ""
        isBookLoading = false
        isLoadingMore = false
        guard searchBook.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else { return }
        isBookLoading = true
        fetchBooks(title: searchBook, offset: 0) {}
    }

    func fetchBooks(title: String, offset: Int, completion: @escaping () -> Void) {
        requestTask?.cancel()
        let id = UUID()
        requestID = id
        isLoadingMore = true
        requestTask = api.fetchBooks(title: title, offset: offset) { [weak self] result in
            DispatchQueue.main.async {
                defer { completion() }
                guard let self, self.requestID == id else { return }
                self.requestTask = nil
                self.isBookLoading = false
                self.isLoadingMore = false
                switch result {
                case .success(let books):
                    self.cache.save(books: books, for: title, offset: offset)
                    self.books = offset == 0 ? books : self.books + books
                    self.offset = offset
                    self.loadedTitle = title
                    self.loadingMoreBookNotPossible = books.isEmpty
                case .failure(let error):
                    if let cached = self.cache.load(for: title, offset: offset), !cached.isEmpty {
                        self.books = offset == 0 ? cached : self.books + cached
                        self.offset = offset
                        self.loadedTitle = title
                        self.loadingMoreBookNotPossible = cached.isEmpty
                    } else {
                        self.errorMessage = error.localizedDescription
                        self.showAlert = true
                    }
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
