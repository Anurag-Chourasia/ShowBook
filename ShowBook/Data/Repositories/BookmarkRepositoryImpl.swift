//
//  BookmarkRepositoryImpl.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 10/11/26.
//

import Foundation
import Combine

final class BookmarkRepositoryImpl: BookmarkRepositoryProtocol {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    var updatedBooksPublisher: AnyPublisher<[Book]?, Never> {
        persistenceController.$updatedBooks.eraseToAnyPublisher()
    }

    func fetchBooks() -> [Book] {
        persistenceController.fetchBooks()
    }

    func saveBook(_ book: Book, imageData: Data?) {
        persistenceController.saveBook(book, imageData: imageData)
    }

    func deleteBook(_ book: Book) {
        persistenceController.deleteBook(book)
    }

    func deleteAllBooks() {
        persistenceController.deleteAllBooks()
    }

    func isBookmarked(_ book: Book) -> Bool {
        if let existing = persistenceController.bookExists(book) {
            return existing.title == book.title
        }
        return false
    }

    func doesBookExist(title: String, authors: [String]?) -> Bool {
        persistenceController.doesBookExist(title: title, authors: authors)
    }

    func doesBookHaveImageData(title: String, authors: [String]?) -> Bool {
        persistenceController.doesBookHaveImageData(title: title, authors: authors)
    }
}
