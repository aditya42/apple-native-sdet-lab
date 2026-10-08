import Foundation
import ContactDomain

protocol ContactAPIClientProtocol: Sendable {
    func fetchContacts() async throws -> [Contact]
}

struct ContactAPIClient: ContactAPIClientProtocol {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchContacts() async throws -> [Contact] {
        let url = baseURL.appending(path: "contacts")
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
    }
}
