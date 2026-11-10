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
    private var bookmarkRepository: any BookmarkRepositoryProtocol
    private let bookmarkSave = BookmarkSaveRequest()

    init(bookmarkRepository: (any BookmarkRepositoryProtocol)? = nil, persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.bookmarkRepository = bookmarkRepository ?? BookmarkRepositoryImpl(persistenceController: persistenceController)
    }

    #if DEBUG
    convenience init() {
        self.init(persistenceController: PersistenceController.inMemory())
    }
    #endif
    var book: Book?
    var imageUrl: URL?
    
    func setUpPersistenceController(controller: PersistenceController) {
        bookmarkSave.cancel()
        persistenceController = controller
        bookmarkRepository = BookmarkRepositoryImpl(persistenceController: controller)
    }

    func setUpPersitenceController(controller: PersistenceController) {
        setUpPersistenceController(controller: controller)
    }
    
    func configure(book: Book, imageUrl: URL?) {
        bookmarkSave.cancel()
        self.book = book
        self.imageUrl = imageUrl
        fetchInitialState()
    }
    
    func fetchInitialState() {
        guard let book = book else { return }
        self.isBookmarked = bookmarkRepository.isBookmarked(book)
    }
    
    func toggleBookmark() {
        guard let book = book else { return }
        isBookmarked.toggle()
        if isBookmarked {
            handleBookmarkAdded{
                
            }
        } else {
            bookmarkSave.cancel()
            bookmarkRepository.deleteBook(book)
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
