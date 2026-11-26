import Foundation
import XCTest
import ContactDomain
@testable import ContactLab

final class APIClientResilienceTests: XCTestCase {
    func testRetryThenSuccessOnTransientHTTP503() async throws {
        let counter = RequestCounter()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ResilienceStubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        ResilienceStubURLProtocol.handler = { request in
            let attempt = counter.next()
            let response = HTTPURLResponse(
                url: request.url!, statusCode: attempt < 3 ? 503 : 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, attempt < 3 ? Data() : Data("[]".utf8))
        }
        defer { ResilienceStubURLProtocol.handler = nil }
        let client = ContactAPIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session, retryDelayNanoseconds: 0
        )
        let result = try await client.fetchContacts()
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(counter.value, 3)
    }

    func testOfflineFailsWithoutRetry() async {
        let counter = RequestCounter()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ResilienceStubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        ResilienceStubURLProtocol.handler = { _ in
            _ = counter.next()
            throw URLError(.notConnectedToInternet)
        }
        defer { ResilienceStubURLProtocol.handler = nil }
        let client = ContactAPIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session, retryDelayNanoseconds: 0
        )
        do {
            _ = try await client.fetchContacts()
            XCTFail("Expected offline error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(counter.value, 1)
    }
}

private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}

private final class ResilienceStubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    private static let lock = NSLock()
    private static var _handler: Handler?
    static var handler: Handler? {
        get { lock.lock(); defer { lock.unlock() }; return _handler }
        set { lock.lock(); defer { lock.unlock() }; _handler = newValue }
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}
