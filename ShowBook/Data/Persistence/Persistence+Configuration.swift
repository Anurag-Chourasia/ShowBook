import CoreData

extension PersistenceController {
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
                persistenceLogger.log("Error loading in-memory store: \(error)", level: .error)
            }
        }
        return container
    }

    static func inMemory(onLoadError: ((Error) -> Void)? = nil) -> PersistenceController {
        PersistenceController(container: createInMemoryPersistentContainer(onLoadError: onLoadError))
    }
}
