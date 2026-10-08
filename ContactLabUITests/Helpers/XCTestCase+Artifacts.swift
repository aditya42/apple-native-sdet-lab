import XCTest

extension XCTestCase {
    @MainActor
    func attachFailureDiagnostics(app: XCUIApplication, name: String = "failure") {
        let screenshot = XCUIScreen.main.screenshot()
        let image = XCTAttachment(screenshot: screenshot)
        image.name = "\(name)-screenshot"
        image.lifetime = .keepAlways
        add(image)

        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "\(name)-ui-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }
}
