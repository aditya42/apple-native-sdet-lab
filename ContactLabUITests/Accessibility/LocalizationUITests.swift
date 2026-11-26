import XCTest

final class LocalizationUITests: XCTestCase {
    @MainActor
    func testLocalizedLaunchAndCoreNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data", "--in-memory-store"]
        app.launchEnvironment["CONTACT_API_BASE_URL"] = "http://127.0.0.1:8080"
        app.launch()
        XCTAssertTrue(app.buttons["contact.add"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["contact.sync"].exists)
        app.buttons["contact.add"].tap()
        XCTAssertTrue(app.textFields["contact.form.firstName"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testRightToLeftLayoutDoesNotHideCoreActions() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data", "--in-memory-store", "-AppleLanguages", "(ar)", "-AppleLocale", "ar_SA"]
        app.launch()
        let add = app.buttons["contact.add"]
        let sync = app.buttons["contact.sync"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        XCTAssertTrue(sync.exists)
        XCTAssertTrue(add.isHittable)
        XCTAssertTrue(sync.isHittable)
    }
}
