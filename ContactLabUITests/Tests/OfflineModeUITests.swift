import XCTest

final class OfflineModeUITests: XCTestCase {
    @MainActor
    func testSyncFailureDoesNotPreventLocalCreation() {
        let testApp = TestApp()
        testApp.launch(offline: true)
        let app = testApp.app

        app.buttons["contact.sync"].tap()
        XCTAssertTrue(app.buttons["contact.add"].waitForExistence(timeout: 5))
        app.buttons["contact.add"].tap()
        let firstName = app.textFields["contact.form.firstName"]
        XCTAssertTrue(firstName.waitForExistence(timeout: 5))
        firstName.tap()
        firstName.typeText("Offline")
        let lastName = app.textFields["contact.form.lastName"]
        lastName.tap()
        lastName.typeText("Test")
        app.buttons["contact.save"].tap()
        XCTAssertTrue(app.staticTexts["Offline Test"].waitForExistence(timeout: 5))
    }
}
