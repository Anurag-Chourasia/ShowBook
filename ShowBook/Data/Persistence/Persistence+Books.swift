import CoreData

extension PersistenceController {
    func fetchBooks() -> [Book] {
        guard storeLoadError == nil else { return [] }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = userScopePredicate()
        do {
            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.compactMap {
                Book(title: $0.title ?? "", ratingsAverage: $0.ratingsAverage, ratingsCount: Int($0.ratingsCount),
                     authorName: $0.authorNames as? [String], coverI: Int($0.coverI), image: $0.image, key: $0.workKey)
            }
        } catch {
            persistenceLogger.log("Failed to fetch books: \(error.localizedDescription)", level: .error)
            return []
        }
    }

    func bookExists(_ book: Book) -> BookEntity? {
        guard storeLoadError == nil else { return nil }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let identityPredicate: NSPredicate
        if let key = book.key, !key.isEmpty { identityPredicate = NSPredicate(format: "workKey == %@", key) }
        else { identityPredicate = NSPredicate(format: "title ==[c] %@", book.title) }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [identityPredicate, userScopePredicate()])
        do { return try context.fetch(fetchRequest).first }
        catch {
            persistenceLogger.log("Failed to fetch book: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    func deleteBook(_ book: Book) {
        guard storeLoadError == nil else { return }
        let context = container.viewContext
        if let bookEntity = bookExists(book) {
            context.delete(bookEntity)
            do {
                try context.save()
                updateBooks(fetchBooks())
            } catch { persistenceLogger.log("Failed to delete book: \(error.localizedDescription)", level: .error) }
        } else {
            persistenceLogger.log("Book does not exist in the database.", level: .info)
        }
    }

    func deleteAllBooks() {
        guard storeLoadError == nil else { return }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = userScopePredicate()
        do {
            let bookEntities = try context.fetch(fetchRequest)
            for bookEntity in bookEntities { context.delete(bookEntity) }
            try context.save()
            updateBooks(fetchBooks())
        } catch { persistenceLogger.log("Failed to delete all books: \(error.localizedDescription)", level: .error) }
    }
}
