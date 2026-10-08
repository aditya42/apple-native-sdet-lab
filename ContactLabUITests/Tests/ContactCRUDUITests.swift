import XCTest

final class ContactCRUDUITests: XCTestCase {
    @MainActor
    private func launchedApp() -> TestApp {
        continueAfterFailure = false
        let testApp = TestApp()
        testApp.launch()
        return testApp
    }

    @MainActor
    func testCreateContact() {
        let testApp = launchedApp()
        let app = testApp.app

        ContactListScreen(app: app).tapAdd()
        ContactFormScreen(app: app).create(
            firstName: "John",
            lastName: "Appleseed",
            phone: "5551234567",
            email: "john@example.com"
        )

        XCTAssertTrue(app.staticTexts["John Appleseed"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testSearchContact() {
        let testApp = launchedApp()
        let app = testApp.app

        ContactListScreen(app: app).tapAdd()
        ContactFormScreen(app: app).create(
            firstName: "Jane",
            lastName: "Doe",
            phone: "5557654321",
            email: "jane@example.com"
        )

        ContactListScreen(app: app).search("Jane")
        XCTAssertTrue(app.staticTexts["Jane Doe"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeleteContact() {
        let testApp = launchedApp()
        let app = testApp.app

        ContactListScreen(app: app).tapAdd()
        ContactFormScreen(app: app).create(
            firstName: "Delete",
            lastName: "Me",
            phone: "5550000000",
            email: "delete@example.com"
        )

        ContactListScreen(app: app).openContact(named: "Delete Me")
        app.buttons["contact.delete"].tap()

        XCTAssertFalse(app.staticTexts["Delete Me"].exists)
    }
}
