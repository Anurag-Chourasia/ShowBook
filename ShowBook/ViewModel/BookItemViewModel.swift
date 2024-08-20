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

    private var persistenceController = PersistenceController.shared
    private var bookItem: Book
    private var imageUrl: URL?

    var item: Book {
        bookItem
    }
    
    var imageURL: URL? {
        imageUrl
    }

    init(item: Book) {
        self.bookItem = item
        self.imageUrl = URL(string: "https://covers.openlibrary.org/b/id/\(item.coverI ?? 0)-M.jpg")
        fetchInitialState()
    }
    
    func setUpPersistenceController(controller : PersistenceController){
        self.persistenceController = controller
        fetchInitialState()
    }

    func configure(imageUrl: URL?) {
        self.imageUrl = imageUrl
        fetchInitialState()
    }
    
    func toggleBookmark() {
        isBookmarked.toggle()
        if isBookmarked {
            handleBookmarkAdded{
                
            }
        } else {
            persistenceController.deleteBook(bookItem)
        }
    }
    
    func fetchInitialState() {
        if let existingBook = persistenceController.bookExists(bookItem), existingBook.title == bookItem.title {
            isBookmarked = true
        } else {
            isBookmarked = false
        }
        authorNames = bookItem.authorName?.joined(separator: ", ") ?? ""
    }
    
    func handleBookmarkAdded(completion: @escaping () -> Void) {
        guard let imageUrl = imageUrl else {
            persistenceController.saveBook(bookItem, imageData: nil)
            completion()  // Call completion when done
            return
        }
        
        DispatchQueue.main.async {
            self.downloadImage(from: imageUrl) { imageData in
                self.persistenceController.saveBook(self.bookItem, imageData: ((imageData?.count ?? 0) > 100 ? imageData : nil))
                completion()  // Call completion when done
            }
        }
    }

    
    func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data)
        }.resume()
    }
    
    func onDragChanged(_ translation: CGSize) {
        showBookmarkButton = translation.width < 0 && abs(translation.width) > 50
    }
}
