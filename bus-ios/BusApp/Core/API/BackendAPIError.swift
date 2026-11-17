import Foundation

enum BackendAPIError: LocalizedError, Equatable {
    case invalidRequest
    case invalidResponse
    case server(statusCode: Int, message: String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            "The app could not create the request."
        case .invalidResponse:
            "The backend returned an invalid response."
        case let .server(_, message):
            message
        case .decodingFailed:
            "The backend returned data the app could not read."
        }
    }
}
