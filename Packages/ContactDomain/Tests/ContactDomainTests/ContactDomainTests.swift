import XCTest
@testable import ContactDomain

final class ContactDomainTests: XCTestCase {
    func testDisplayNameCombinesFirstAndLastName() {
        let contact = Contact(firstName: "John", lastName: "Appleseed", phone: "", email: "")
        XCTAssertEqual(contact.displayName, "John Appleseed")
    }

    func testSearchMatchesNameCaseInsensitively() {
        let contacts = [
            Contact(firstName: "John", lastName: "Appleseed", phone: "5551234567", email: "john@example.com"),
            Contact(firstName: "Jane", lastName: "Doe", phone: "5557654321", email: "jane@example.com")
        ]
        XCTAssertEqual(ContactSearch.filter(contacts, query: "john").count, 1)
    }

    func testValidatorRejectsMissingName() {
        XCTAssertThrowsError(try ContactValidator.validate(Contact(firstName: "", lastName: "", phone: "", email: "")))
    }
}
