//
//  Persistence.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import CoreData
import Combine
import FoundationKit

let persistenceLogger: any AppLogger = UnifiedLogger(subsystem: "com.showbook.app", category: "Persistence")

class PersistenceController: ObservableObject {
    struct BookmarkOwner: Equatable {
        let email: String
        let uuid: UUID?
        let session: UUID
    }

    private static var bookmarkSession = UUID()
    static func invalidateBookmarkSession() { bookmarkSession = UUID() }
    var bookmarkOwner: BookmarkOwner {
        BookmarkOwner(email: currentUserEmail, uuid: currentUserUUID, session: Self.bookmarkSession)
    }

    static let shared = PersistenceController()
    @Published var updatedBooks: [Book]?
    @Published var storeLoadError: Error?
    var isStoreLoaded: Bool { storeLoadError == nil }
    var container: NSPersistentContainer {
        didSet { container.viewContext.automaticallyMergesChangesFromParent = true }
    }

    var currentUserUUID: UUID? {
        if let uuidString = UserDefaults.standard.string(forKey: "LoggedInUserUUID"),
           let uuid = UUID(uuidString: uuidString) {
            return uuid
        }
        return nil
    }

    var currentUserEmail: String {
        UserDefaults.standard.string(forKey: "LoggedInUserEmail") ?? ""
    }

    init(container: NSPersistentContainer) {
        self.container = container
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private init() {
        let managedObjectModel = PersistenceController.managedObjectModel()
        container = NSPersistentContainer(name: "ShowBook", managedObjectModel: managedObjectModel)
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores { [weak self] (_, error) in
            if let error = error {
                self?.storeLoadError = error
                persistenceLogger.log("Error loading Core Data stores: \(error). Existing data files are preserved.", level: .error)
                return
            }
            self?.storeLoadError = nil
        }
    }

    func retryLoadingStore(completion: ((Result<Void, Error>) -> Void)? = nil) {
        container.loadPersistentStores { [weak self] (_, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.storeLoadError = error
                    completion?(.failure(error))
                } else {
                    self?.storeLoadError = nil
                    completion?(.success(()))
                }
            }
        }
    }

    #if DEBUG
    func simulateStoreLoadFailure(error: Error) { self.storeLoadError = error }
    func clearStoreLoadFailure() { self.storeLoadError = nil }
    #endif

    func saveContext() {
        let context = container.viewContext
        do { try context.save() }
        catch { persistenceLogger.log("Error saving context: \(error)", level: .error) }
    }

    func deleteAllData(entity: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            let context = container.viewContext
            try context.execute(deleteRequest)
            try context.save()
        } catch { persistenceLogger.log("Error deleting data: \(error)", level: .error) }
    }

    func updateBooks(_ books: [Book]) {
        DispatchQueue.main.async { self.updatedBooks = books }
    }

    func saveBook(_ book: Book, imageData: Data?) {
        guard storeLoadError == nil else { return }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let identityPredicate: NSPredicate
        if let key = book.key, !key.isEmpty { identityPredicate = NSPredicate(format: "workKey == %@", key) }
        else { identityPredicate = NSPredicate(format: "title ==[c] %@", book.title) }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [identityPredicate, userScopePredicate()])

        do {
            let results = try context.fetch(fetchRequest)
            let bookEntity = results.first ?? BookEntity(context: context)
            bookEntity.workKey = book.key
            bookEntity.title = book.title
            bookEntity.ratingsAverage = book.ratingsAverage ?? 0.0
            bookEntity.ratingsCount = Int32(book.ratingsCount ?? 0)
            bookEntity.coverI = Int32(book.coverI ?? 0)
            bookEntity.email = currentUserEmail
            bookEntity.userUUID = currentUserUUID
            bookEntity.ownerID = currentUserUUID?.uuidString.lowercased()
            if let authorNames = book.authorName { bookEntity.authorNames = authorNames as NSObject }
            bookEntity.image = imageData
            try context.save()
            updateBooks(fetchBooks())
        } catch { persistenceLogger.log("Failed to save book: \(error.localizedDescription)", level: .error) }
    }
}
