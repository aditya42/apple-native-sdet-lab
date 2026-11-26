import Foundation
import ContactDomain

protocol ContactAPIClientProtocol: Sendable {
    func fetchContacts() async throws -> [Contact]
}

struct ContactAPIClient: ContactAPIClientProtocol {
    let baseURL: URL
    let session: URLSession
    let maxAttempts: Int
    let retryDelayNanoseconds: UInt64

    init(
        baseURL: URL,
        session: URLSession = .shared,
        maxAttempts: Int = 3,
        retryDelayNanoseconds: UInt64 = 200_000_000
    ) {
        self.baseURL = baseURL
        self.session = session
        self.maxAttempts = max(1, maxAttempts)
        self.retryDelayNanoseconds = retryDelayNanoseconds
    }

    func fetchContacts() async throws -> [Contact] {
        let url = baseURL.appending(path: "contacts")
        for attempt in 1...maxAttempts {
            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw NetworkError.httpStatus(http.statusCode)
                }
                do {
                    return try JSONDecoder().decode([Contact].self, from: data)
                } catch {
                    throw NetworkError.decoding(error)
                }
            } catch {
                let retryable: Bool
                if case NetworkError.httpStatus(let status) = error {
                    retryable = status == 429 || (500...599).contains(status)
                } else if let urlError = error as? URLError {
                    retryable = [.timedOut, .networkConnectionLost, .cannotConnectToHost].contains(urlError.code)
                } else {
                    retryable = false
                }
                guard retryable && attempt < maxAttempts else { throw error }
                try await Task.sleep(nanoseconds: retryDelayNanoseconds)
            }
        }
        throw NetworkError.invalidResponse
    }
}
