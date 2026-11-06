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
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    func setUpPersistenceController(controller: PersistenceController) {
        persistenceController = controller
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
        bookmarkBooks = persistenceController.fetchBooks()
        if bookmarkBooks.isEmpty {
            showAlert = true
            errorMessage = "No record found"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            self.isLoading = false
        }
    }
}
