import XCTest

final class LaunchPerformanceTests: XCTestCase {
    @MainActor
    func testColdLaunchPerformance() {
        let app = XCUIApplication()

        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            MainActor.assumeIsolated {
                app.launch()
                app.terminate()
            }
        }
    }
}
