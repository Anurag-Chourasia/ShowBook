import CoreData

extension PersistenceController {
    enum IdentityMigrationError: Error { case conflictingOwner }

    func userScopePredicate() -> NSPredicate {
        if let currentUUID = currentUserUUID {
            let email = currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let uuidString = currentUUID.uuidString.lowercased()
            if !email.isEmpty {
                let format = "userUUID == %@ OR ownerID ==[c] %@ OR (userUUID == nil AND ownerID == nil AND email ==[c] %@)"
                return NSPredicate(format: format, currentUUID as CVarArg, uuidString, email)
            } else {
                return NSPredicate(format: "userUUID == %@ OR ownerID ==[c] %@", currentUUID as CVarArg, uuidString)
            }
        } else {
            let email = currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !email.isEmpty {
                return NSPredicate(format: "email ==[c] %@", email)
            } else {
                return NSPredicate(format: "userUUID == nil AND ownerID == nil")
            }
        }
    }

    func activateCloudIdentity(email: String, uuid: UUID,
                               save: (NSManagedObjectContext) throws -> Void = { try $0.save() }) throws {
        if let storeLoadError { throw storeLoadError }
        let context = container.newBackgroundContext()
        try context.performAndWait {
            do {
                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !cleanEmail.isEmpty {
                    let conflictingRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
                    conflictingRequest.predicate = NSPredicate(
                        format: "email ==[c] %@ AND userUUID != nil AND userUUID != %@",
                        cleanEmail,
                        uuid as CVarArg
                    )
                    if try context.count(for: conflictingRequest) > 0 {
                        throw IdentityMigrationError.conflictingOwner
                    }
                }
                _ = try Self.migrateBookmarks(fromEmail: email, toUUID: uuid, in: context, save: { _ in })
                let prefRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
                if let pref = try context.fetch(prefRequest).first {
                    pref.userUUID = uuid
                    pref.ownerID = uuid.uuidString.lowercased()
                }
                if context.hasChanges { try save(context) }
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    @discardableResult
    func migrateBookmarks(fromEmail: String, toUUID: UUID) throws -> Int {
        try Self.migrateBookmarks(fromEmail: fromEmail, toUUID: toUUID, in: container.viewContext)
    }

    @discardableResult
    func rekeyBookmarks(fromEmail: String, toUUID: UUID) throws -> Int {
        try migrateBookmarks(fromEmail: fromEmail, toUUID: toUUID)
    }

    @discardableResult
    static func migrateBookmarks(
        fromEmail: String,
        toUUID: UUID,
        in context: NSManagedObjectContext,
        save: (NSManagedObjectContext) throws -> Void = { try $0.save() }
    ) throws -> Int {
        let cleanEmail = fromEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        if !cleanEmail.isEmpty {
            fetchRequest.predicate = NSPredicate(
                format: "(email ==[c] %@ OR email == nil OR email == '') AND userUUID == nil AND ownerID == nil",
                cleanEmail
            )
        } else {
            fetchRequest.predicate = NSPredicate(
                format: "(email == nil OR email == '') AND userUUID == nil AND ownerID == nil"
            )
        }

        let booksToMigrate = try context.fetch(fetchRequest)
        guard !booksToMigrate.isEmpty else { return 0 }

        do {
            for book in booksToMigrate {
                book.userUUID = toUUID
                book.ownerID = toUUID.uuidString.lowercased()
                if (book.email == nil || book.email?.isEmpty == true) && !cleanEmail.isEmpty {
                    book.email = cleanEmail
                }
            }
            try save(context)
            return booksToMigrate.count
        } catch {
            context.rollback()
            throw error
        }
    }

    @discardableResult
    static func rollbackBookmarkMigration(
        forUUID: UUID,
        in context: NSManagedObjectContext,
        save: (NSManagedObjectContext) throws -> Void = { try $0.save() }
    ) throws -> Int {
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userUUID == %@", forUUID as CVarArg)
        let books = try context.fetch(fetchRequest)
        guard !books.isEmpty else { return 0 }

        do {
            for book in books {
                book.userUUID = nil
                book.ownerID = nil
            }
            try save(context)
            return books.count
        } catch {
            context.rollback()
            throw error
        }
    }
}
