import XCTest

@MainActor
struct ContactListScreen {
    let app: XCUIApplication

    var addButton: XCUIElement { app.buttons["contact.add"] }
    var syncButton: XCUIElement { app.buttons["contact.sync"] }
    var searchField: XCUIElement { app.searchFields.firstMatch }

    func tapAdd() {
        addButton.tap()
    }

    func openContact(named name: String) {
        let label = app.staticTexts[name]
        XCTAssertTrue(label.waitForExistence(timeout: 3), "Contact \(name) did not appear")
        label.tap()
    }

    func search(_ query: String) {
        searchField.tap()
        searchField.typeText(query)
    }
}
