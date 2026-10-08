import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server returned an invalid response."
        case .httpStatus(let status): "The server returned HTTP \(status)."
        case .decoding: "The server returned data the app could not read."
        }
    }
}
