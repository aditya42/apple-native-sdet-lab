import SwiftUI
import ContactDomain

struct ContactListView: View {
    @StateObject var viewModel: ContactListViewModel
    @State private var adding = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredContacts.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Contacts", systemImage: "person.crop.circle.badge.xmark")
                        .accessibilityIdentifier(AccessibilityID.ContactList.empty)
                } else {
                    List(viewModel.filteredContacts) { contact in
                        NavigationLink {
                            ContactDetailView(
                                contact: contact,
                                onSave: viewModel.save,
                                onDelete: viewModel.delete
                            )
                        } label: {
                            VStack(alignment: .leading) {
                                Text(contact.displayName)
                                    .font(.headline)
                                Text(contact.phone)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("contact.row.\(contact.id.uuidString)")
                    }
                }
            }
            .accessibilityIdentifier(AccessibilityID.ContactList.screen)
            .navigationTitle("Contacts")
            .searchable(text: $viewModel.query, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await viewModel.sync() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Sync Contacts")
                    .accessibilityIdentifier(AccessibilityID.ContactList.sync)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        adding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Contact")
                    .accessibilityIdentifier(AccessibilityID.ContactList.add)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Syncing")
                        .accessibilityIdentifier(AccessibilityID.ContactList.loading)
                }
            }
            .alert("Sync Failed", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "")
                    .accessibilityIdentifier(AccessibilityID.ContactList.error)
            }
            .sheet(isPresented: $adding) {
                ContactFormView(onSave: viewModel.save)
            }
        }
    }
}
