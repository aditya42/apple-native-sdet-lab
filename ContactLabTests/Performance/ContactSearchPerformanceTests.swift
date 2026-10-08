import XCTest
import ContactDomain

final class ContactSearchPerformanceTests: XCTestCase {
    func testSearchTenThousandContactsPerformance() {
        let contacts = (0..<10_000).map {
            Contact(firstName: "User", lastName: "\($0)", phone: "555\($0)", email: "user\($0)@example.com")
        }

        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            _ = ContactSearch.filter(contacts, query: "User 9999")
        }
    }
}
