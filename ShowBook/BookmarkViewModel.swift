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
    
    var persistenceController = PersistenceController.shared
    
    func setUpPersitenceController(controller : PersistenceController){
        persistenceController = controller
    }
    
    func loadBookmarks() {
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
