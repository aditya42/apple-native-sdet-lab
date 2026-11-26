import XCTest

final class AccessibilityContractTests: XCTestCase {
    @MainActor
    func testPrimaryControlsExposeStableIdentifiersAndLabels() {
        let testApp = TestApp()
        testApp.launch()
        let app = testApp.app

        let add = app.buttons["contact.add"]
        let sync = app.buttons["contact.sync"]
        XCTAssertTrue(add.exists)
        XCTAssertTrue(sync.exists)
        XCTAssertEqual(add.label, "Add Contact")
        XCTAssertEqual(sync.label, "Sync Contacts")
        XCTAssertTrue(add.isHittable)
        XCTAssertTrue(sync.isHittable)
        add.tap()
        for id in ["contact.form.firstName", "contact.form.lastName", "contact.form.phone", "contact.form.email"] {
            let field = app.textFields[id]
            XCTAssertTrue(field.waitForExistence(timeout: 5), "Missing accessible field: \(id)")
            XCTAssertFalse(field.label.isEmpty, "Empty VoiceOver label: \(id)")
        }
        XCTAssertTrue(app.buttons["contact.save"].exists)
        XCTAssertFalse(app.buttons["contact.save"].label.isEmpty)
    }
}
