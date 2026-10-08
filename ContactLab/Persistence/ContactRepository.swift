import CoreData
import ContactDomain

@MainActor
protocol ContactRepositoryProtocol {
    func all() throws -> [Contact]
    func replaceAll(with contacts: [Contact]) throws
    func save(_ contact: Contact) throws
    func delete(id: UUID) throws
    func reset() throws
}

@MainActor
final class CoreDataContactRepository: ContactRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(stack: CoreDataStack) {
        context = stack.container.viewContext
    }

    func all() throws -> [Contact] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ContactEntity")
        let objects = try context.fetch(request)
        return objects.compactMap(Self.map)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func replaceAll(with contacts: [Contact]) throws {
        try reset()
        for contact in contacts { try save(contact) }
    }

    func save(_ contact: Contact) throws {
        try ContactValidator.validate(contact)
        let request = NSFetchRequest<NSManagedObject>(entityName: "ContactEntity")
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)
        let object = try context.fetch(request).first
            ?? NSEntityDescription.insertNewObject(forEntityName: "ContactEntity", into: context)
        object.setValue(contact.id, forKey: "id")
        object.setValue(contact.firstName, forKey: "firstName")
        object.setValue(contact.lastName, forKey: "lastName")
        object.setValue(contact.phone, forKey: "phone")
        object.setValue(contact.email, forKey: "email")
        object.setValue(contact.isFavorite, forKey: "isFavorite")
        try context.save()
    }

    func delete(id: UUID) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ContactEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
        }
    }

    func reset() throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ContactEntity")
        try context.execute(NSBatchDeleteRequest(fetchRequest: request))
        context.reset()
    }

    private static func map(_ object: NSManagedObject) -> Contact? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let firstName = object.value(forKey: "firstName") as? String,
            let lastName = object.value(forKey: "lastName") as? String,
            let phone = object.value(forKey: "phone") as? String,
            let email = object.value(forKey: "email") as? String
        else { return nil }

        return Contact(
            id: id,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            email: email,
            isFavorite: object.value(forKey: "isFavorite") as? Bool ?? false
        )
    }
}
