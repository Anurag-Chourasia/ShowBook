//
//  ToggleBookmarkUseCase.swift
//  ShowBook
//

import Foundation

protocol ToggleBookmarkUseCaseProtocol: Sendable {
    func saveBookmark(_ book: Book, imageData: Data?)
    func isBookmarked(_ book: Book) -> Bool
    func deleteBookmark(_ book: Book)
}

final class ToggleBookmarkUseCase: ToggleBookmarkUseCaseProtocol {
    private let repository: any BookmarkRepositoryProtocol

    init(repository: any BookmarkRepositoryProtocol) {
        self.repository = repository
    }

    func saveBookmark(_ book: Book, imageData: Data?) {
        repository.saveBook(book, imageData: imageData)
    }

    func isBookmarked(_ book: Book) -> Bool {
        repository.isBookmarked(book)
    }

    func deleteBookmark(_ book: Book) {
        repository.deleteBook(book)
    }
}
