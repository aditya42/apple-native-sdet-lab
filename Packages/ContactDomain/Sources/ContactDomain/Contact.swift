import Foundation

public struct Contact: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var firstName: String
    public var lastName: String
    public var phone: String
    public var email: String
    public var isFavorite: Bool

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        phone: String,
        email: String,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.email = email
        self.isFavorite = isFavorite
    }

    public var displayName: String {
        [firstName, lastName]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
    }
}
