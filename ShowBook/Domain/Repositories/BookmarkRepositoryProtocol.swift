//
//  BookmarkRepositoryProtocol.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 10/11/26.
//

import Foundation
import Combine

protocol BookmarkRepositoryProtocol: AnyObject {
    var updatedBooksPublisher: AnyPublisher<[Book]?, Never> { get }
    func fetchBooks() -> [Book]
    func saveBook(_ book: Book, imageData: Data?)
    func deleteBook(_ book: Book)
    func deleteAllBooks()
    func isBookmarked(_ book: Book) -> Bool
    func doesBookExist(title: String, authors: [String]?) -> Bool
    func doesBookHaveImageData(title: String, authors: [String]?) -> Bool
    @discardableResult
    func rekeyBookmarks(fromEmail: String, toUUID: UUID) throws -> Int
}
