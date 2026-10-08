import XCTest

@MainActor
struct TestApp {
    let app: XCUIApplication

    init() {
        self.app = XCUIApplication()
    }

    func launch(resetData: Bool = true, inMemoryStore: Bool = false) {
        app.launchArguments = ["--uitesting"]
        if resetData { app.launchArguments.append("--reset-data") }
        if inMemoryStore { app.launchArguments.append("--in-memory-store") }
        app.launchEnvironment["CONTACT_API_BASE_URL"] = ProcessInfo.processInfo.environment["CONTACT_API_BASE_URL"] ?? "http://127.0.0.1:8080"
        app.launch()
    }
}
