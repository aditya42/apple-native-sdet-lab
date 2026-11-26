import XCTest

@MainActor
struct ContactFormScreen {
    let app: XCUIApplication

    func create(firstName: String, lastName: String, phone: String, email: String) {
        let first = app.textFields["contact.form.firstName"]
        XCTAssertTrue(first.waitForExistence(timeout: 2))
        enter(firstName, into: first)

        let last = app.textFields["contact.form.lastName"]
        enter(lastName, into: last)

        let phoneField = app.textFields["contact.form.phone"]
        enter(phone, into: phoneField)

        let emailField = app.textFields["contact.form.email"]
        enter(email, into: emailField)

        app.buttons["contact.save"].tap()
    }

    private func enter(_ value: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        if !field.hasKeyboardFocus {
            field.tap()
        }
        XCTAssertTrue(field.hasKeyboardFocus, "Text field did not gain keyboard focus: \(field.identifier)")
        field.typeText(value)
    }
}
