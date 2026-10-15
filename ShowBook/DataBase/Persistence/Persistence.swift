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

class PersistenceController {
    static let shared = PersistenceController()
    private let credentialQueue = DispatchQueue(label: "ShowBook.credentials", qos: .userInitiated)
    @Published var updatedBooks: [Book]?
    var container: NSPersistentContainer {
        didSet { container.viewContext.automaticallyMergesChangesFromParent = true }
    }

    init(container: NSPersistentContainer) {
        self.container = container
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private init() {
        let managedObjectModel = PersistenceController.managedObjectModel()
        container = NSPersistentContainer(name: "ShowBook", managedObjectModel: managedObjectModel)
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error {
                fatalError("Error loading Core Data stores: \(error)")
            }
            self?.migrateLegacyCredentials { result in
                if case .failure = result {
                    // Do not log credentials or managed objects. Login/next launch can retry.
                    print("Credential migration could not complete; it will be retried.")
                }
            }
        }
    }

    static func managedObjectModel() -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: "ShowBook", withExtension: "momd") else {
            fatalError("Failed to find data model")
        }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load data model")
        }
        return managedObjectModel
    }

    static func createInMemoryPersistentContainer() -> NSPersistentContainer {
        let managedObjectModel = managedObjectModel()
        let container = NSPersistentContainer(name: "ShowBook", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Error loading Core Data stores: \(error)")
            }
        }
        return container
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
            
            saveContext()
        } catch {
            print("Error saving default country name: \(error)")
        }
    }
    
    func fetchSelectedCountryName() -> String? {
        let context = container.viewContext
        
        do {
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
        do { try context.save() }
        catch { context.delete(user); throw error }
    }

    func registerUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = container.newBackgroundContext()
        credentialQueue.async {
            context.performAndWait {
                let result = Result { try Self.createUser(in: context, email: email, password: password) }
                DispatchQueue.main.async { completion(result) }
            }
        }
    }

    func authenticate(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = container.newBackgroundContext()
        credentialQueue.async {
            context.performAndWait {
                let result = Result {
                    let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "email == %@", email.lowercased())
                    guard let user = try context.fetch(request).first else { throw CredentialError.missingAccount }
                    if let hash = user.passwordHash {
                        guard try PasswordCredential.verify(password, encoded: hash) else { throw CredentialError.wrongPassword }
                    } else {
                        guard let legacy = user.password, legacy == password else { throw CredentialError.wrongPassword }
                        user.passwordHash = try PasswordCredential.make(password)
                    }
                    user.password = nil
                    user.isSuccessfullyLoggedIn = true
                    do { try context.save() }
                    catch { context.rollback(); throw error }
                }
                DispatchQueue.main.async { completion(result) }
            }
        }
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
        let context = container.viewContext
        
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        do {
            let users = try context.fetch(fetchRequest)
            return users.first
        } catch {
            print("Error fetching user: \(error)")
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
            print("User with email \(email) not found")
        }
    }
    

    func saveBook(_ book: Book, imageData: Data?) {
        let context = container.viewContext
        let userEmail = UserDefaults.standard.value(forKey: "LoggedInUserEmail") as? String ?? ""
        
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "title == %@", book.title),
            NSPredicate(format: "email == %@", userEmail)
        ]
        
        if let ratingsAverage = book.ratingsAverage {
            predicates.append(NSPredicate(format: "ratingsAverage == %f", ratingsAverage))
        }
        
        if let ratingsCount = book.ratingsCount {
            predicates.append(NSPredicate(format: "ratingsCount == %d", Int32(ratingsCount)))
        }
        
        if let coverI = book.coverI {
            predicates.append(NSPredicate(format: "coverI == %d", Int32(coverI)))
        }
        
        if let authorName = book.authorName?.first {
            predicates.append(NSPredicate(format: "ANY authorNames == %@", authorName))
        }
        
        fetchRequest.predicate = book.key.map { NSPredicate(format: "workKey == %@ AND email == %@", $0, userEmail) }
            ?? NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
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
        let userEmail = UserDefaults.standard.value(forKey: "LoggedInUserEmail") as? String ?? ""

        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", userEmail)

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
        let context = container.viewContext
        let userEmail = UserDefaults.standard.value(forKey: "LoggedInUserEmail") as? String ?? ""
        
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = book.key.map { NSPredicate(format: "workKey == %@ AND email == %@", $0, userEmail) }
            ?? NSPredicate(format: "title == %@ AND email == %@", book.title, userEmail)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Failed to fetch book: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteBook(_ book: Book) {
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
        let context = container.viewContext
        
        // Create a fetch request to retrieve all BookEntity instances
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        
        do {
            // Fetch all book entities
            let bookEntities = try context.fetch(fetchRequest)
            
            // Delete all fetched book entities
            for bookEntity in bookEntities {
                context.delete(bookEntity)
            }
            
            // Save the context to persist changes
            try context.save()
            
            // Update the books list if necessary
            updateBooks(fetchBooks())
        } catch {
            print("Failed to delete all books: \(error.localizedDescription)")
        }
    }

    
    func doesBookExist(title: String, authors: [String]?) -> Bool {
        let context = container.viewContext
        let userEmail = UserDefaults.standard.value(forKey: "LoggedInUserEmail") as? String ?? ""

        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()

        // Create the predicate for matching title and email
        let titlePredicate = NSPredicate(format: "title == %@", title)
        let emailPredicate = NSPredicate(format: "email == %@", userEmail)

        // Check if authors is nil or empty
        let authorPredicate: NSPredicate
        if let authors = authors, !authors.isEmpty {
            // Create an array of predicates for each author in the authors array
            let authorPredicates = authors.map { author in
                NSPredicate(format: "ANY authorNames == %@", author)
            }
            // Combine all author predicates using OR
            authorPredicate = NSCompoundPredicate(type: .or, subpredicates: authorPredicates)
        } else {
            // If authors is nil or empty, the predicate should always be true
            authorPredicate = NSPredicate(format: "TRUEPREDICATE")
        }

        // Combine all predicates using AND
        let finalPredicate = NSCompoundPredicate(type: .and, subpredicates: [titlePredicate, emailPredicate, authorPredicate])

        fetchRequest.predicate = finalPredicate

        do {
            let results = try context.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Failed to fetch book: \(error.localizedDescription)")
            return false
        }
    }

    func doesBookHaveImageData(title: String, authors: [String]?) -> Bool {
        let context = container.viewContext
        let userEmail = UserDefaults.standard.value(forKey: "LoggedInUserEmail") as? String ?? ""

        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()

        // Create the predicate for matching title and email
        let titlePredicate = NSPredicate(format: "title == %@", title)
        let emailPredicate = NSPredicate(format: "email == %@", userEmail)

        // Check if authors is nil or empty
        let authorPredicate: NSPredicate
        if let authors = authors, !authors.isEmpty {
            // Create an array of predicates for each author in the authors array
            let authorPredicates = authors.map { author in
                NSPredicate(format: "ANY authorNames == %@", author)
            }
            // Combine all author predicates using OR
            authorPredicate = NSCompoundPredicate(type: .or, subpredicates: authorPredicates)
        } else {
            // If authors is nil or empty, the predicate should always be true
            authorPredicate = NSPredicate(format: "TRUEPREDICATE")
        }

        // Combine all predicates using AND
        let finalPredicate = NSCompoundPredicate(type: .and, subpredicates: [titlePredicate, emailPredicate, authorPredicate])

        fetchRequest.predicate = finalPredicate

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
