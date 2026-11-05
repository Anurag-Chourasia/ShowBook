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
    private var persistenceController: PersistenceController
    private let bookmarkSave = BookmarkSaveRequest()

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    var book: Book?
    var imageUrl: URL?
    
    func setUpPersitenceController(controller : PersistenceController){
        bookmarkSave.cancel()
        persistenceController = controller
    }
    
    func configure(book: Book, imageUrl: URL?) {
        bookmarkSave.cancel()
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
            bookmarkSave.cancel()
            persistenceController.deleteBook(book)
        }
    }
    
    func handleBookmarkAdded(completion: @escaping () -> Void) {
        guard let book else { completion(); return }
        bookmarkSave.start(book: book, imageURL: imageUrl, controller: persistenceController,
                           download: downloadImage, completion: completion)
    }

    func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        bookmarkSave.download(from: url, completion: completion)
    }
}
