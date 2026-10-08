import SwiftUI
import ContactDomain

struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String
    @State private var lastName: String
    @State private var phone: String
    @State private var email: String
    @State private var isFavorite: Bool
    @State private var errorMessage: String?

    let originalID: UUID
    let onSave: (Contact) throws -> Void

    init(contact: Contact? = nil, onSave: @escaping (Contact) throws -> Void) {
        originalID = contact?.id ?? UUID()
        _firstName = State(initialValue: contact?.firstName ?? "")
        _lastName = State(initialValue: contact?.lastName ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
        _email = State(initialValue: contact?.email ?? "")
        _isFavorite = State(initialValue: contact?.isFavorite ?? false)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("First name", text: $firstName)
                    .accessibilityIdentifier(AccessibilityID.ContactForm.firstName)
                TextField("Last name", text: $lastName)
                    .accessibilityIdentifier(AccessibilityID.ContactForm.lastName)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                    .accessibilityIdentifier(AccessibilityID.ContactForm.phone)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier(AccessibilityID.ContactForm.email)
                Toggle("Favorite", isOn: $isFavorite)
                    .accessibilityIdentifier(AccessibilityID.ContactForm.favorite)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier(AccessibilityID.ContactForm.error)
                }
            }
            .navigationTitle("Contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier(AccessibilityID.ContactForm.cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityIdentifier(AccessibilityID.ContactForm.save)
                }
            }
        }
    }

    private func save() {
        let contact = Contact(
            id: originalID,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            email: email,
            isFavorite: isFavorite
        )
        do {
            try onSave(contact)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
