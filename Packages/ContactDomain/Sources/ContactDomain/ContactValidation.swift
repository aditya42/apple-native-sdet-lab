import Foundation

public enum ContactValidationError: Error, Equatable, LocalizedError {
    case missingName
    case invalidEmail
    case invalidPhone

    public var errorDescription: String? {
        switch self {
        case .missingName: "Enter a first or last name."
        case .invalidEmail: "Enter a valid email address."
        case .invalidPhone: "Enter a valid phone number."
        }
    }
}

public enum ContactValidator {
    public static func validate(_ contact: Contact) throws {
        if contact.displayName.isEmpty {
            throw ContactValidationError.missingName
        }
        if !contact.email.isEmpty && !contact.email.contains("@") {
            throw ContactValidationError.invalidEmail
        }
        let digits = contact.phone.filter(\.isNumber)
        if !contact.phone.isEmpty && digits.count < 7 {
            throw ContactValidationError.invalidPhone
        }
    }
}
