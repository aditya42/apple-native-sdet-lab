import SwiftUI
import ContactDomain

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: Contact
    let onSave: (Contact) throws -> Void
    let onDelete: (Contact) throws -> Void
    @State private var editing = false

    var body: some View {
        List {
            Section("Contact") {
                LabeledContent("Name", value: contact.displayName)
                LabeledContent("Phone", value: contact.phone)
                LabeledContent("Email", value: contact.email)
                LabeledContent("Favorite", value: contact.isFavorite ? "Yes" : "No")
            }

            Button("Delete Contact", role: .destructive) {
                try? onDelete(contact)
                dismiss()
            }
            .accessibilityIdentifier(AccessibilityID.ContactDetail.delete)
        }
        .accessibilityIdentifier(AccessibilityID.ContactDetail.screen)
        .navigationTitle(contact.displayName)
        .toolbar {
            Button("Edit") { editing = true }
                .accessibilityIdentifier(AccessibilityID.ContactDetail.edit)
        }
        .sheet(isPresented: $editing) {
            ContactFormView(contact: contact, onSave: onSave)
        }
    }
}
