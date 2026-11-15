import Combine

typealias UserPreferenceEntity = UserPreference

extension PersistenceController: BookmarkRepositoryProtocol, UserPreferenceRepositoryProtocol {
    var updatedBooksPublisher: AnyPublisher<[Book]?, Never> {
        $updatedBooks.eraseToAnyPublisher()
    }

    func isBookmarked(_ book: Book) -> Bool {
        if let existing = bookExists(book) {
            return existing.title == book.title
        }
        return false
    }
}
