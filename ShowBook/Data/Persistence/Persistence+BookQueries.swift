import CoreData

extension PersistenceController {
    func doesBookExist(title: String, authors: [String]?) -> Bool {
        guard storeLoadError == nil else { return false }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let titlePredicate = NSPredicate(format: "title ==[c] %@", title)
        let authorPredicate: NSPredicate
        if let authors = authors, !authors.isEmpty {
            let authorPredicates = authors.map { NSPredicate(format: "ANY authorNames == %@", $0) }
            authorPredicate = NSCompoundPredicate(type: .or, subpredicates: authorPredicates)
        } else {
            authorPredicate = NSPredicate(format: "TRUEPREDICATE")
        }
        let scope = userScopePredicate()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [titlePredicate, authorPredicate, scope])

        do {
            return try !context.fetch(fetchRequest).isEmpty
        } catch {
            persistenceLogger.log("Failed to fetch book: \(error.localizedDescription)", level: .error)
            return false
        }
    }

    func doesBookHaveImageData(title: String, authors: [String]?) -> Bool {
        guard storeLoadError == nil else { return false }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let titlePredicate = NSPredicate(format: "title ==[c] %@", title)
        let authorPredicate: NSPredicate
        if let authors = authors, !authors.isEmpty {
            let authorPredicates = authors.map { NSPredicate(format: "ANY authorNames == %@", $0) }
            authorPredicate = NSCompoundPredicate(type: .or, subpredicates: authorPredicates)
        } else {
            authorPredicate = NSPredicate(format: "TRUEPREDICATE")
        }
        let scope = userScopePredicate()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [titlePredicate, authorPredicate, scope])

        do {
            guard let bookEntity = try context.fetch(fetchRequest).first else { return false }
            return bookEntity.image != nil
        } catch {
            persistenceLogger.log("Failed to fetch book: \(error.localizedDescription)", level: .error)
            return false
        }
    }
}
