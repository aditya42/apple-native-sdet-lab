import XCTest
import ContactDomain
@testable import ContactLab

@MainActor
final class CoreDataContactRepositoryTests: XCTestCase {
    func testSaveReadDeleteRoundTrip() throws {
        let repository = CoreDataContactRepository(stack: CoreDataStack(inMemory: true))
        let contact = Contact(firstName: "Jane", lastName: "Doe", phone: "5557654321", email: "jane@example.com")

        try repository.save(contact)
        XCTAssertEqual(try repository.all(), [contact])

        try repository.delete(id: contact.id)
        XCTAssertTrue(try repository.all().isEmpty)
    }
}
