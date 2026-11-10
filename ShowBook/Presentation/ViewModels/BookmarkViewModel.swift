//
//  BookmarkViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import Combine

class BookmarkViewModel: ObservableObject {
    @Published var bookmarkBooks: [Book] = []
    @Published var errorMessage: String = ""
    @Published var showAlert = false
    @Published var isLoading = false
    
    var persistenceController: PersistenceController
    var bookmarkRepository: any BookmarkRepositoryProtocol
    var fetchBookmarksUseCase: any FetchBookmarksUseCaseProtocol

    init(
        fetchBookmarksUseCase: (any FetchBookmarksUseCaseProtocol)? = nil,
        bookmarkRepository: (any BookmarkRepositoryProtocol)? = nil,
        persistenceController: PersistenceController
    ) {
        self.persistenceController = persistenceController
        let repo = bookmarkRepository ?? BookmarkRepositoryImpl(persistenceController: persistenceController)
        self.bookmarkRepository = repo
        self.fetchBookmarksUseCase = fetchBookmarksUseCase ?? FetchBookmarksUseCase(repository: repo)
    }

    #if DEBUG
    convenience init() {
        self.init(persistenceController: PersistenceController.inMemory())
    }
    #endif

    func setUpPersistenceController(controller: PersistenceController) {
        persistenceController = controller
        let repo = BookmarkRepositoryImpl(persistenceController: controller)
        bookmarkRepository = repo
        fetchBookmarksUseCase = FetchBookmarksUseCase(repository: repo)
    }

    func setUpPersitenceController(controller: PersistenceController) {
        setUpPersistenceController(controller: controller)
    }

    func loadBookmarks() {
        if persistenceController.storeLoadError != nil {
            showAlert = true
            errorMessage = "Library storage is temporarily unavailable. Your saved data is intact."
            return
        }
        isLoading = true
        bookmarkBooks = fetchBookmarksUseCase.execute()
        if bookmarkBooks.isEmpty {
            showAlert = true
            errorMessage = "No record found"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            self.isLoading = false
        }
    }
}
