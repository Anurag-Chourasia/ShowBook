//
//  BookItemViewModel.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import SwiftUI
import Combine

class BookItemViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var authorNames: String = ""
    @Published var isBookmarked: Bool = false
    @Published var showBookmarkButton: Bool = false

    private var persistenceController: PersistenceController
    private var bookmarkRepository: any BookmarkRepositoryProtocol
    private let bookmarkSave = BookmarkSaveRequest()
    private var bookItem: Book
    private var imageUrl: URL?

    var item: Book {
        bookItem
    }
    
    var imageURL: URL? {
        imageUrl
    }

    init(item: Book, bookmarkRepository: (any BookmarkRepositoryProtocol)? = nil, persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.bookmarkRepository = bookmarkRepository ?? BookmarkRepositoryImpl(persistenceController: persistenceController)
        self.bookItem = item
        self.imageUrl = URL(string: "https://covers.openlibrary.org/b/id/\(item.coverI ?? 0)-M.jpg")
        fetchInitialState()
    }

    #if DEBUG
    convenience init(item: Book) {
        self.init(item: item, persistenceController: PersistenceController.inMemory())
    }
    #endif
    
    func setUpPersistenceController(controller: PersistenceController) {
        bookmarkSave.cancel()
        self.persistenceController = controller
        self.bookmarkRepository = BookmarkRepositoryImpl(persistenceController: controller)
        fetchInitialState()
    }

    func configure(imageUrl: URL?) {
        bookmarkSave.cancel()
        self.imageUrl = imageUrl
        fetchInitialState()
    }
    
    func toggleBookmark() {
        isBookmarked.toggle()
        if isBookmarked {
            handleBookmarkAdded{
                
            }
        } else {
            bookmarkSave.cancel()
            bookmarkRepository.deleteBook(bookItem)
        }
    }
    
    func fetchInitialState() {
        isBookmarked = bookmarkRepository.isBookmarked(bookItem)
        authorNames = bookItem.authorName?.joined(separator: ", ") ?? ""
    }
    
    func handleBookmarkAdded(completion: @escaping () -> Void) {
        bookmarkSave.start(book: bookItem, imageURL: imageUrl, controller: persistenceController,
                           download: downloadImage, completion: completion)
    }

    func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        bookmarkSave.download(from: url, completion: completion)
    }

    func onTao() {
        withAnimation(.smooth) {
            showBookmarkButton.toggle()
        }
    }
}

/// Host-owned lifetime guard shared by both bookmark presentation adapters.
final class BookmarkSaveRequest {
    private var generation = UUID()
    private var task: URLSessionDataTask?

    deinit { task?.cancel() }

    func cancel() {
        generation = UUID()
        task?.cancel()
        task = nil
    }

    func download(from url: URL, completion: @escaping (Data?) -> Void) {
        task = URLSession.shared.dataTask(with: url) { data, _, _ in completion(data) }
        task?.resume()
    }

    func start(book: Book, imageURL: URL?, controller: PersistenceController,
               download: (URL, @escaping (Data?) -> Void) -> Void,
               completion: @escaping () -> Void) {
        cancel()
        let requestID = generation
        let owner = controller.bookmarkOwner
        let context = controller.container.viewContext
        let receive: (Data?) -> Void = { [weak self] data in
            context.perform { [weak self] in
                defer { completion() }
                guard let self, self.generation == requestID,
                      controller.container.viewContext === context,
                      controller.bookmarkOwner == owner else { return }
                self.task = nil
                controller.saveBook(book, imageData: (data?.count ?? 0) > 100 ? data : nil)
            }
        }
        if let imageURL {
            download(imageURL, receive)
        } else {
            receive(nil)
        }
    }
}
