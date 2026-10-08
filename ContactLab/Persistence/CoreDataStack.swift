import CoreData

final class CoreDataStack: @unchecked Sendable {
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "ContactEntity"
        entity.managedObjectClassName = "NSManagedObject"

        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            return attribute
        }

        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("firstName", .stringAttributeType),
            attribute("lastName", .stringAttributeType),
            attribute("phone", .stringAttributeType),
            attribute("email", .stringAttributeType),
            attribute("isFavorite", .booleanAttributeType)
        ]
        model.entities = [entity]

        container = NSPersistentContainer(name: "ContactLab", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            precondition(error == nil, "CoreData store failed: \(String(describing: error))")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
