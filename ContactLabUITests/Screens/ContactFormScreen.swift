import XCTest

@MainActor
struct ContactFormScreen {
    let app: XCUIApplication

    func create(firstName: String, lastName: String, phone: String, email: String) {
        let first = app.textFields["contact.form.firstName"]
        XCTAssertTrue(first.waitForExistence(timeout: 2))
        first.tap()
        first.typeText(firstName)

        let last = app.textFields["contact.form.lastName"]
        last.tap()
        last.typeText(lastName)

        let phoneField = app.textFields["contact.form.phone"]
        phoneField.tap()
        phoneField.typeText(phone)

        let emailField = app.textFields["contact.form.email"]
        emailField.tap()
        emailField.typeText(email)

        app.buttons["contact.save"].tap()
    }
}
