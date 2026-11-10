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

    init(bookmarkRepository: (any BookmarkRepositoryProtocol)? = nil, persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.bookmarkRepository = bookmarkRepository ?? BookmarkRepositoryImpl(persistenceController: persistenceController)
    }

    #if DEBUG
    convenience init() {
        self.init(persistenceController: PersistenceController.inMemory())
    }
    #endif

    func setUpPersistenceController(controller: PersistenceController) {
        persistenceController = controller
        bookmarkRepository = BookmarkRepositoryImpl(persistenceController: controller)
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
        bookmarkBooks = bookmarkRepository.fetchBooks()
        if bookmarkBooks.isEmpty {
            showAlert = true
            errorMessage = "No record found"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            self.isLoading = false
        }
    }
}
