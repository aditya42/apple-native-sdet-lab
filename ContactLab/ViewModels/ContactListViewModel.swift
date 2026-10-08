import Foundation
import ContactDomain

@MainActor
final class ContactListViewModel: ObservableObject {
    @Published private(set) var contacts: [Contact] = []
    @Published var query = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: ContactRepositoryProtocol
    private let api: ContactAPIClientProtocol

    init(repository: ContactRepositoryProtocol, api: ContactAPIClientProtocol) {
        self.repository = repository
        self.api = api
        loadLocal()
    }

    var filteredContacts: [Contact] {
        ContactSearch.filter(contacts, query: query)
    }

    func loadLocal() {
        contacts = (try? repository.all()) ?? []
    }

    func sync() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let remote = try await api.fetchContacts()
            try repository.replaceAll(with: remote)
            contacts = try repository.all()
        } catch {
            errorMessage = error.localizedDescription
            loadLocal()
        }
    }

    func save(_ contact: Contact) throws {
        try repository.save(contact)
        loadLocal()
    }

    func delete(_ contact: Contact) throws {
        try repository.delete(id: contact.id)
        loadLocal()
    }
}
