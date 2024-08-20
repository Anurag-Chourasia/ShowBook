//
//  BookmarkButtonViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import Combine

class BookmarkButtonViewModel: ObservableObject {
    @Published var isBookmarked: Bool = false
    private var persistenceController = PersistenceController.shared
    var book: Book?
    var imageUrl: URL?
    
    func setUpPersitenceController(controller : PersistenceController){
        persistenceController = controller
    }
    
    func configure(book: Book, imageUrl: URL?) {
        self.book = book
        self.imageUrl = imageUrl
        fetchInitialState()
    }
    
    func fetchInitialState() {
        guard let book = book else { return }
        if let existingBook = persistenceController.bookExists(book), existingBook.title == book.title {
            self.isBookmarked = true
        } else {
            self.isBookmarked = false
        }
    }
    
    func toggleBookmark() {
        guard let book = book else { return }
        isBookmarked.toggle()
        if isBookmarked {
            handleBookmarkAdded{
                
            }
        } else {
            persistenceController.deleteBook(book)
        }
    }
    
    func handleBookmarkAdded(completion: @escaping () -> Void) {
        guard let bookItem = book else {
            // Handle the case where bookItem is nil if needed
            completion()
            return
        }

        guard let imageUrl = imageUrl else {
            // Save the book without image data and call completion
            persistenceController.saveBook(bookItem, imageData: nil)
            completion()
            return
        }
        
        // Asynchronously download the image
        DispatchQueue.global(qos: .userInitiated).async {
            self.downloadImage(from: imageUrl) { imageData in
                // Ensure we're on the main thread when updating Core Data
                DispatchQueue.main.async {
                    self.persistenceController.saveBook(bookItem, imageData: ((imageData?.count ?? 0) > 100 ? imageData : nil))
                    completion()  // Call completion when done
                }
            }
        }
    }

    
    private func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data)
        }.resume()
    }
}

