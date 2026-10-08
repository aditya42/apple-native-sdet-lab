import Foundation
import XCTest
@testable import ContactLab

final class APIClientTests: XCTestCase {
    override func tearDown() {
        StubURLProtocol.removeHandler()
        super.tearDown()
    }

    func testInvalidHTTPStatusMapsToNetworkError() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)

        StubURLProtocol.setHandler { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            let response = HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, Data())
        }

        let client = ContactAPIClient(
            baseURL: URL(string: "https://example.test")!,
            session: session
        )

        do {
            _ = try await client.fetchContacts()
            XCTFail("Expected request to fail")
        } catch NetworkError.httpStatus(let status) {
            XCTAssertEqual(status, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private final class HandlerStore: @unchecked Sendable {
        private let lock = NSLock()
        private var handler: Handler?

        func set(_ handler: Handler?) {
            lock.lock()
            self.handler = handler
            lock.unlock()
        }

        func get() -> Handler? {
            lock.lock()
            defer { lock.unlock() }
            return handler
        }
    }

    private static let handlerStore = HandlerStore()

    static func setHandler(_ handler: @escaping Handler) {
        handlerStore.set(handler)
    }

    static func removeHandler() {
        handlerStore.set(nil)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handlerStore.get() else {
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

    override func stopLoading() { }
}
