import XCTest

final class AppLifecycleUITests: XCTestCase {
    @MainActor
    func testDraftSurvivesBackgroundForegroundTransition() {
        let testApp = TestApp()
        testApp.launch()
        let app = testApp.app

        ContactListScreen(app: app).tapAdd()
        let firstName = app.textFields["contact.form.firstName"]
        firstName.tap()
        firstName.typeText("Steve")

        XCUIDevice.shared.press(.home)
        app.activate()

        XCTAssertEqual(firstName.value as? String, "Steve")
    }

    @MainActor
    func testPersistedContactSurvivesRelaunch() {
        let testApp = TestApp()
        testApp.launch()
        let app = testApp.app

        ContactListScreen(app: app).tapAdd()
        ContactFormScreen(app: app).create(
            firstName: "Persisted",
            lastName: "User",
            phone: "5551112222",
            email: "p@example.com"
        )

        app.terminate()
        testApp.launch(resetData: false)

        XCTAssertTrue(app.staticTexts["Persisted User"].waitForExistence(timeout: 3))
    }
}
