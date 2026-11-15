import SwiftUI

extension BookmarkButton {
    init(
        book: Book,
        imageUrl: URL? = nil,
        bookmarkRepository: any BookmarkRepositoryProtocol,
        persistenceController: PersistenceController
    ) {
        self.init(
            book: book,
            imageUrl: imageUrl,
            viewModel: BookmarkButtonViewModel(
                bookmarkRepository: bookmarkRepository,
                persistenceController: persistenceController
            )
        )
    }

    #if DEBUG
    init(book: Book, imageUrl: URL? = nil) {
        self.init(book: book, imageUrl: imageUrl, persistenceController: PersistenceController.inMemory())
    }
    #endif
}
