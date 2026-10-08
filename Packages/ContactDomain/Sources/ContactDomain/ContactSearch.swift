import Foundation

public enum ContactSearch {
    public static func filter(_ contacts: [Contact], query: String) -> [Contact] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return contacts }

        return contacts.filter { contact in
            contact.displayName.localizedCaseInsensitiveContains(normalized)
                || contact.phone.localizedCaseInsensitiveContains(normalized)
                || contact.email.localizedCaseInsensitiveContains(normalized)
        }
    }
}
