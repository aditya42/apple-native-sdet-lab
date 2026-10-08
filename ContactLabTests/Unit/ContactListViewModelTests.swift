import XCTest
import ContactDomain
@testable import ContactLab

@MainActor
final class ContactListViewModelTests: XCTestCase {
    func testSavePersistsAndReloadsContact() throws {
        let repository = InMemoryRepository()
        let viewModel = ContactListViewModel(repository: repository, api: StubAPI())
        let contact = Contact(firstName: "John", lastName: "Appleseed", phone: "5551234567", email: "john@example.com")

        try viewModel.save(contact)

        XCTAssertEqual(viewModel.contacts, [contact])
    }

    func testSyncFallsBackToCachedContactsWhenAPIThrows() async throws {
        let cached = Contact(firstName: "Cached", lastName: "User", phone: "", email: "")
        let repository = InMemoryRepository(contacts: [cached])
        let viewModel = ContactListViewModel(repository: repository, api: ThrowingAPI())

        await viewModel.sync()

        XCTAssertEqual(viewModel.contacts, [cached])
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

@MainActor
private final class InMemoryRepository: ContactRepositoryProtocol {
    var contacts: [Contact]
    init(contacts: [Contact] = []) { self.contacts = contacts }
    func all() throws -> [Contact] { contacts }
    func replaceAll(with contacts: [Contact]) throws { self.contacts = contacts }
    func save(_ contact: Contact) throws {
        contacts.removeAll { $0.id == contact.id }
        contacts.append(contact)
    }
    func delete(id: UUID) throws { contacts.removeAll { $0.id == id } }
    func reset() throws { contacts.removeAll() }
}

private struct StubAPI: ContactAPIClientProtocol {
    func fetchContacts() async throws -> [Contact] { [] }
}

private struct ThrowingAPI: ContactAPIClientProtocol {
    enum Failure: Error { case expected }
    func fetchContacts() async throws -> [Contact] { throw Failure.expected }
}
