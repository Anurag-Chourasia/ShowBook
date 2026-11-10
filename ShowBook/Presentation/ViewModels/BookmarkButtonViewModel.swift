//
//  BookmarkButtonViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import Foundation
import Combine

class BookmarkButtonViewModel: ObservableObject {
    @Published var isBookmarked: Bool = false
    private var persistenceController: PersistenceController
    private var bookmarkRepository: any BookmarkRepositoryProtocol
    private var toggleBookmarkUseCase: any ToggleBookmarkUseCaseProtocol
    private let bookmarkSave = BookmarkSaveRequest()

    init(
        toggleBookmarkUseCase: (any ToggleBookmarkUseCaseProtocol)? = nil,
        bookmarkRepository: (any BookmarkRepositoryProtocol)? = nil,
        persistenceController: PersistenceController
    ) {
        self.persistenceController = persistenceController
        let repo = bookmarkRepository ?? BookmarkRepositoryImpl(persistenceController: persistenceController)
        self.bookmarkRepository = repo
        self.toggleBookmarkUseCase = toggleBookmarkUseCase ?? ToggleBookmarkUseCase(repository: repo)
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
        let repo = BookmarkRepositoryImpl(persistenceController: controller)
        bookmarkRepository = repo
        toggleBookmarkUseCase = ToggleBookmarkUseCase(repository: repo)
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
        self.isBookmarked = toggleBookmarkUseCase.isBookmarked(book)
    }
    
    func toggleBookmark() {
        guard let book = book else { return }
        isBookmarked.toggle()
        if isBookmarked {
            handleBookmarkAdded{
                
            }
        } else {
            bookmarkSave.cancel()
            toggleBookmarkUseCase.deleteBookmark(book)
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
