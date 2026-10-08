import XCTest

final class AccessibilityContractTests: XCTestCase {
    @MainActor
    func testPrimaryControlsExposeStableIdentifiers() {
        let testApp = TestApp()
        testApp.launch()
        let app = testApp.app

        XCTAssertTrue(app.buttons["contact.add"].exists)
        XCTAssertTrue(app.buttons["contact.sync"].exists)
    }
}
