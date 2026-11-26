import XCTest

@MainActor
struct ContactFormScreen {
    let app: XCUIApplication

    func create(firstName: String, lastName: String, phone: String, email: String) {
        enter(firstName, into: app.textFields["contact.form.firstName"])
        enter(lastName, into: app.textFields["contact.form.lastName"])
        enter(phone, into: app.textFields["contact.form.phone"])
        enter(email, into: app.textFields["contact.form.email"])
        app.buttons["contact.save"].tap()
    }

    private func enter(_ value: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 10),
                      "Missing contact form field: \(field.identifier)")
        XCTAssertTrue(field.isHittable, "Field is not hittable: \(field.identifier)")
        field.tap()
        // Wait for the iOS keyboard before sending keystrokes on slower CI simulators.
        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 5) {
            field.tap()
            XCTAssertTrue(keyboard.waitForExistence(timeout: 5),
                          "Keyboard did not appear for: \(field.identifier)")
        }
        field.typeText(value)
    }
}
