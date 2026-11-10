//
//  Persistence.swift
//  ShowBook
//
//  Created by Anurag Chourasia on 17/08/24.
//

import CoreData
import UIKit
import CommonCrypto
import Security
import Combine

class PersistenceController: ObservableObject {
    struct BookmarkOwner: Equatable {
        let email: String
        let uuid: UUID?
        let session: UUID
    }
    /// Deliberate session token bumped during account transitions to prevent cross-account writes.
    private static var bookmarkSession = UUID()
    // Called at host login/logout transitions, including a return to the same account.
    static func invalidateBookmarkSession() { bookmarkSession = UUID() }
    var bookmarkOwner: BookmarkOwner {
        BookmarkOwner(email: currentUserEmail, uuid: currentUserUUID, session: Self.bookmarkSession)
    }

    /// The application-lifetime persistent store coordinator for live app runs.
    ///
    /// Lifetime: Bound to the application lifecycle at `ShowBookApp` composition root.
    /// In production, `ShowBookApp` supplies this instance to `UserViewModel` and downstream views.
    /// In tests or previews, callers should construct independent instances (e.g. `PersistenceController.inMemory()`)
    /// instead of mutating `PersistenceController.shared`.
    static let shared = PersistenceController()
    private let credentialQueue = DispatchQueue(label: "ShowBook.credentials", qos: .userInitiated)
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
                // Present recoverable store-load failures without automatic data deletion
                self?.storeLoadError = error
                print("Error loading Core Data stores: \(error). Existing data files are preserved.")
                return
            }
            self?.storeLoadError = nil
            self?.migrateLegacyCredentials { result in
                if case .failure = result {
                    // Do not log credentials or managed objects. Login/next launch can retry.
                    print("Credential migration could not complete; it will be retried.")
                }
            }
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
    func simulateStoreLoadFailure(error: Error) {
        self.storeLoadError = error
    }

    func clearStoreLoadFailure() {
        self.storeLoadError = nil
    }
    #endif

    static func managedObjectModel() -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: "ShowBook", withExtension: "momd") else {
            fatalError("Failed to find data model")
        }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load data model")
        }
        return managedObjectModel
    }

    static func createInMemoryPersistentContainer(onLoadError: ((Error) -> Void)? = nil) -> NSPersistentContainer {
        let managedObjectModel = managedObjectModel()
        let container = NSPersistentContainer(name: "ShowBook", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (_, error) in
            if let error = error {
                onLoadError?(error)
                print("Error loading in-memory store: \(error)")
            }
        }
        return container
    }

    /// Creates an independent, in-memory `PersistenceController` isolated from the live store.
    static func inMemory(onLoadError: ((Error) -> Void)? = nil) -> PersistenceController {
        PersistenceController(container: createInMemoryPersistentContainer(onLoadError: onLoadError))
    }

    func saveCountryModel(_ countryModel: CountryModel) {
        let context = container.viewContext
        
        let countryEntity = CountryEntity(context: context)
        countryEntity.status = countryModel.status
        countryEntity.statusCode = Int16(countryModel.statusCode)
        countryEntity.version = countryModel.version
        countryEntity.access = countryModel.access
        countryEntity.total = Int16(countryModel.total)
        countryEntity.offset = Int16(countryModel.offset)
        countryEntity.limit = Int16(countryModel.limit)
        
        for (_, datum) in countryModel.data {
            let datumEntity = DatumEntity(context: context)
            datumEntity.country = datum.country
            
            let regionEntity = RegionEntity(context: context)
            regionEntity.region = datum.region.rawValue
            
            datumEntity.region = regionEntity
            countryEntity.addToData(datumEntity)
        }
        
        saveContext()
    }
    
    func saveDefaultCountryName(selectedCountryName: String) {
        let context = container.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<CountryEntity> = CountryEntity.fetchRequest()
            let countryEntities = try context.fetch(fetchRequest)
            
            if let existingCountryEntity = countryEntities.first {
                existingCountryEntity.selectedCountryName = selectedCountryName
            } else {
                let newCountryEntity = CountryEntity(context: context)
                newCountryEntity.selectedCountryName = selectedCountryName
            }

            let prefRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
            let prefEntities = try context.fetch(prefRequest)
            let pref = prefEntities.first ?? UserPreference(context: context)
            pref.selectedCountryName = selectedCountryName
            if let uuid = currentUserUUID {
                pref.userUUID = uuid
                pref.ownerID = uuid.uuidString.lowercased()
            }
            
            saveContext()
        } catch {
            print("Error saving default country name: \(error)")
        }
    }
    
    func fetchSelectedCountryName() -> String? {
        let context = container.viewContext
        
        do {
            let prefRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
            if let pref = try context.fetch(prefRequest).first,
               let country = pref.selectedCountryName, !country.isEmpty {
                return country
            }

            let fetchRequest: NSFetchRequest<CountryEntity> = CountryEntity.fetchRequest()
            let countryEntities = try context.fetch(fetchRequest)
            
            guard let firstCountryEntity = countryEntities.first else {
                print("No CountryEntity found")
                return nil
            }
            
            return firstCountryEntity.selectedCountryName
        } catch {
            print("Error fetching selected country name: \(error)")
            return nil
        }
    }
    
    func fetchCountryModel() -> CountryModel? {
        let context = container.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<CountryEntity> = CountryEntity.fetchRequest()
            let countryEntities = try context.fetch(fetchRequest)

            guard let firstCountryEntity = countryEntities.first else {
                return nil
            }
            
            
            var data: [String: Datum] = [:]
            firstCountryEntity.data?.forEach { (datumEntity) in
                if let datum = datumEntity as? DatumEntity {
                    let regionEnum = Region(rawValue: datum.region?.region ?? Region.africa.rawValue)
                    data[datum.country ?? ""] = Datum(country: datum.country ?? "", region: regionEnum)
                }
            }
            
            let countryModel = CountryModel(status: firstCountryEntity.status ?? "",
                                            statusCode: Int(firstCountryEntity.statusCode),
                                            version: firstCountryEntity.version ?? "",
                                            access: firstCountryEntity.access ?? "",
                                            total: Int(firstCountryEntity.total),
                                            offset: Int(firstCountryEntity.offset),
                                            limit: Int(firstCountryEntity.limit),
                                            data: data)
            
            return countryModel
        } catch {
            print("Error fetching CountryModel: \(error)")
            return nil
        }
    }
    
    private func saveContext() {
        let context = container.viewContext
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func deleteAllData(entity: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            let context = container.viewContext
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Error deleting data: \(error)")
        }
    }
    
    // Synchronous entry point retained for fixtures; app signup uses registerUser off-main.
    func saveUser(email: String, password: String) -> Bool {
        do {
            try Self.createUser(in: container.viewContext, email: email, password: password)
            return true
        } catch { return false }
    }

    private static func createUser(in context: NSManagedObjectContext, email: String, password: String) throws {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())
        guard try context.count(for: request) == 0 else { throw CredentialError.duplicateAccount }
        let hash = try PasswordCredential.make(password)
        let user = UserEntity(context: context)
        user.email = email.lowercased()
        user.passwordHash = hash
        user.password = nil
        user.isSuccessfullyLoggedIn = true
        user.userUUID = UUID()
        do { try context.save() }
        catch { context.delete(user); throw error }
    }

    func migrateLegacyCredentials(completion: @escaping (Result<Void, Error>) -> Void) {
        let context = container.newBackgroundContext()
        credentialQueue.async {
            context.performAndWait {
                let result = Result { try Self.migrateLegacyCredentials(in: context) }
                DispatchQueue.main.async { completion(result) }
            }
        }
    }


    // Separate transaction per account: failure preserves that account for a later retry.
    static func migrateLegacyCredentials(
        in context: NSManagedObjectContext,
        hashPassword: (String) throws -> String = PasswordCredential.make,
        save: (NSManagedObjectContext) throws -> Void = { try $0.save() }
    ) throws {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "password != nil")
        var firstFailure: Error?
        for user in try context.fetch(request) {
            do {
                guard let plaintext = user.password else { continue }
                if let existing = user.passwordHash {
                    // Never erase the legacy value behind a corrupt or mismatched hash.
                    guard try PasswordCredential.verify(plaintext, encoded: existing) else { throw CredentialError.invalidRecord }
                } else {
                    user.passwordHash = try hashPassword(plaintext)
                }
                user.password = nil
                try save(context)
            } catch {
                context.rollback()
                if firstFailure == nil { firstFailure = error }
            }
        }
        if let firstFailure { throw firstFailure }
    }

    func fetchUser(email: String) -> UserEntity? {
        guard storeLoadError == nil else { return nil }
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email ==[c] %@", email.lowercased())
        
        do {
            let users = try context.fetch(fetchRequest)
            return users.first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }

    func fetchUser(uuid: UUID) -> UserEntity? {
        guard storeLoadError == nil else { return nil }
        let context = container.viewContext

        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userUUID == %@", uuid as CVarArg)

        do {
            let users = try context.fetch(fetchRequest)
            return users.first
        } catch {
            print("Error fetching user by uuid: \(error)")
            return nil
        }
    }
    
    func doesUserExist(email: String) -> Bool {
            let context = container.viewContext
            
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "email == %@", email)
            
            do {
                let users = try context.fetch(fetchRequest)
                return !users.isEmpty
            } catch {
                print("Error fetching user: \(error)")
                return false
            }
        }
    
    func logOutUser(email: String) {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        do {
            let users = try context.fetch(fetchRequest)
            users.first?.isSuccessfullyLoggedIn = false
        } catch {
            print("Error fetching user: \(error)")
            return
        }
        saveContext()
    }
    
    func logInUser(email: String) {
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        do {
            let users = try context.fetch(fetchRequest)
            users.first?.isSuccessfullyLoggedIn = true
        } catch {
            print("Error fetching user: \(error)")
            return
        }
        saveContext()
    }
    
    func deleteUser(email: String) {
        let context = container.viewContext
        
        if let user = fetchUser(email: email) {
            context.delete(user)
            saveContext()
        } else {
            print("User not found")
        }
    }
    

    func saveBook(_ book: Book, imageData: Data?) {
        guard storeLoadError == nil else { return }
        let context = container.viewContext
        let userEmail = currentUserEmail
        let userUUID = currentUserUUID

        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let scope = userScopePredicate()
        let identityPredicate: NSPredicate
        if let key = book.key, !key.isEmpty {
            identityPredicate = NSPredicate(format: "workKey == %@", key)
        } else {
            identityPredicate = NSPredicate(format: "title ==[c] %@", book.title)
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [identityPredicate, scope])

        do {
            let results = try context.fetch(fetchRequest)
            let bookEntity: BookEntity

            if let existingBook = results.first {
                bookEntity = existingBook
            } else {
                bookEntity = BookEntity(context: context)
            }

            bookEntity.workKey = book.key
            bookEntity.title = book.title
            bookEntity.ratingsAverage = book.ratingsAverage ?? 0.0
            bookEntity.ratingsCount = Int32(book.ratingsCount ?? 0)
            bookEntity.coverI = Int32(book.coverI ?? 0)
            bookEntity.email = userEmail
            bookEntity.userUUID = userUUID
            bookEntity.ownerID = userUUID?.uuidString.lowercased()

            if let authorNames = book.authorName {
                bookEntity.authorNames = authorNames as NSObject
            }

            bookEntity.image = imageData

            try context.save()

            updateBooks(fetchBooks())
        } catch {
            print("Failed to save book: \(error.localizedDescription)")
        }
    }

    func fetchBooks() -> [Book] {
        guard storeLoadError == nil else { return [] }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = userScopePredicate()

        do {
            let bookEntities = try context.fetch(fetchRequest)
            let books = bookEntities.compactMap { bookEntity in
                Book(
                    title: bookEntity.title ?? "",
                    ratingsAverage: bookEntity.ratingsAverage,
                    ratingsCount: Int(bookEntity.ratingsCount),
                    authorName: bookEntity.authorNames as? [String],
                    coverI: Int(bookEntity.coverI),
                    image: bookEntity.image,
                    key: bookEntity.workKey
                )
            }
            return books
        } catch {
            print("Failed to fetch books: \(error.localizedDescription)")
            return []
        }
    }

    func bookExists(_ book: Book) -> BookEntity? {
        guard storeLoadError == nil else { return nil }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        let scope = userScopePredicate()
        let identityPredicate: NSPredicate
        if let key = book.key, !key.isEmpty {
            identityPredicate = NSPredicate(format: "workKey == %@", key)
        } else {
            identityPredicate = NSPredicate(format: "title ==[c] %@", book.title)
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [identityPredicate, scope])

        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Failed to fetch book: \(error.localizedDescription)")
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
            } catch {
                print("Failed to delete book: \(error.localizedDescription)")
            }
        } else {
            print("Book does not exist in the database.")
        }
    }

    func deleteAllBooks() {
        guard storeLoadError == nil else { return }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = userScopePredicate()

        do {
            let bookEntities = try context.fetch(fetchRequest)
            for bookEntity in bookEntities {
                context.delete(bookEntity)
            }
            try context.save()
            updateBooks(fetchBooks())
        } catch {
            print("Failed to delete all books: \(error.localizedDescription)")
        }
    }

    func doesBookExist(title: String, authors: [String]?) -> Bool {
        guard storeLoadError == nil else { return false }
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()

        let titlePredicate = NSPredicate(format: "title ==[c] %@", title)
        let authorPredicate: NSPredicate
        if let authors = authors, !authors.isEmpty {
            let authorPredicates = authors.map { author in
                NSPredicate(format: "ANY authorNames == %@", author)
            }
            authorPredicate = NSCompoundPredicate(type: .or, subpredicates: authorPredicates)
        } else {
            authorPredicate = NSPredicate(format: "TRUEPREDICATE")
        }

        let scope = userScopePredicate()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [titlePredicate, authorPredicate, scope])

        do {
            let results = try context.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Failed to fetch book: \(error.localizedDescription)")
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
            let authorPredicates = authors.map { author in
                NSPredicate(format: "ANY authorNames == %@", author)
            }
            authorPredicate = NSCompoundPredicate(type: .or, subpredicates: authorPredicates)
        } else {
            authorPredicate = NSPredicate(format: "TRUEPREDICATE")
        }

        let scope = userScopePredicate()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [titlePredicate, authorPredicate, scope])

        do {
            let results = try context.fetch(fetchRequest)
            guard let bookEntity = results.first else {
                return false
            }
            return bookEntity.image != nil
        } catch {
            print("Failed to fetch book: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - UUID Bookmark Migration and Local Account Linking

    func userScopePredicate() -> NSPredicate {
        if let currentUUID = currentUserUUID {
            let email = currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let uuidString = currentUUID.uuidString.lowercased()
            if !email.isEmpty {
                return NSPredicate(format: "userUUID == %@ OR ownerID ==[c] %@ OR (userUUID == nil AND ownerID == nil AND email ==[c] %@)", currentUUID as CVarArg, uuidString, email)
            } else {
                return NSPredicate(format: "userUUID == %@ OR ownerID ==[c] %@", currentUUID as CVarArg, uuidString)
            }
        } else {
            let email = currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return NSPredicate(format: "email ==[c] %@", email)
        }
    }

    enum IdentityMigrationError: Error { case conflictingOwner }

    /// One isolated transaction: a failed link or save cannot publish half a migration.
    func activateCloudIdentity(email: String, uuid: UUID,
                               save: (NSManagedObjectContext) throws -> Void = { try $0.save() }) throws {
        if let storeLoadError { throw storeLoadError }
        let context = container.newBackgroundContext()
        try context.performAndWait {
            do {
                _ = try Self.linkLocalAccount(email: email, toUUID: uuid, in: context, save: { _ in })
                _ = try Self.migrateBookmarks(fromEmail: email, toUUID: uuid, in: context, save: { _ in })
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
    static func migrateBookmarks(
        fromEmail: String,
        toUUID: UUID,
        in context: NSManagedObjectContext,
        save: (NSManagedObjectContext) throws -> Void = { try $0.save() }
    ) throws -> Int {
        let cleanEmail = fromEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else { return 0 }

        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "email ==[c] %@ AND userUUID == nil",
            cleanEmail
        )

        let booksToMigrate = try context.fetch(fetchRequest)
        guard !booksToMigrate.isEmpty else { return 0 }

        do {
            for book in booksToMigrate {
                book.userUUID = toUUID
                book.ownerID = toUUID.uuidString.lowercased()
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

    @discardableResult
    static func linkLocalAccount(
        email: String,
        toUUID: UUID,
        in context: NSManagedObjectContext,
        save: (NSManagedObjectContext) throws -> Void = { try $0.save() }
    ) throws -> UserEntity? {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty else { return nil }

        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email ==[c] %@", cleanEmail)

        let users = try context.fetch(fetchRequest)
        guard let user = users.first else { return nil }

        if let owner = user.userUUID, owner != toUUID {
            // Local credential records already have a UUID before first cloud linking.
            // Preserve that supported bridge, but never rebind an existing library owner.
            let owned: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            owned.predicate = NSPredicate(format: "userUUID == %@", owner as CVarArg)
            if try context.count(for: owned) > 0 { throw IdentityMigrationError.conflictingOwner }
        }

        do {
            user.userUUID = toUUID
            try save(context)
            return user
        } catch {
            context.rollback()
            throw error
        }
    }


    private func updateBooks(_ books: [Book]) {
        DispatchQueue.main.async {
            self.updatedBooks = books
        }
    }
}
public extension NSManagedObject {

    convenience init(context: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entity, insertInto: context)
    }

}

// MARK: - Password credentials

enum CredentialError: LocalizedError {
    case duplicateAccount, missingAccount, wrongPassword, invalidRecord, derivationFailed
    var errorDescription: String? {
        switch self {
        case .duplicateAccount: return "User with this email already exists"
        case .missingAccount: return "Sign Up first to login"
        case .wrongPassword: return "Wrong Password"
        case .invalidRecord, .derivationFailed: return "Unable to verify credentials. Please try again."
        }
    }
}

enum PasswordCredential {
    private static let rounds: UInt32 = 600_000
    private static let saltSize = 16
    private static let keySize = 32

    static func make(_ password: String) throws -> String {
        var salt = [UInt8](repeating: 0, count: saltSize)
        guard SecRandomCopyBytes(kSecRandomDefault, salt.count, &salt) == errSecSuccess else {
            throw CredentialError.derivationFailed
        }
        let key = try derive(password, salt: salt)
        return "pbkdf2-sha256$1$600000$\(Data(salt).base64EncodedString())$\(Data(key).base64EncodedString())"
    }

    static func verify(_ password: String, encoded: String) throws -> Bool {
        let fields = encoded.split(separator: "$", omittingEmptySubsequences: false)
        guard fields.count == 5, fields[0] == "pbkdf2-sha256", fields[1] == "1", fields[2] == "600000",
              let salt = Data(base64Encoded: String(fields[3])), salt.count == saltSize,
              let expected = Data(base64Encoded: String(fields[4])), expected.count == keySize else {
            throw CredentialError.invalidRecord
        }
        let actual = try derive(password, salt: Array(salt))
        // Compare all bytes; do not return at the first mismatch.
        var difference: UInt8 = 0
        for (a, b) in zip(actual, expected) { difference |= a ^ b }
        return difference == 0
    }

    private static func derive(_ password: String, salt: [UInt8]) throws -> [UInt8] {
        var key = [UInt8](repeating: 0, count: keySize)
        let length = password.utf8.count
        let status = password.withCString { bytes in
            salt.withUnsafeBufferPointer { saltBytes in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), bytes, length,
                                    saltBytes.baseAddress, saltBytes.count,
                                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds, &key, keySize)
            }
        }
        guard status == kCCSuccess else { throw CredentialError.derivationFailed }
        return key
    }
}

// MARK: - BookmarkRepositoryProtocol & UserPreferenceRepositoryProtocol Conformance
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

