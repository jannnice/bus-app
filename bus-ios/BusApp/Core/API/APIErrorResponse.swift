import Foundation

struct APIErrorResponse: Decodable, Equatable {
    let code: String
    let message: String
    let timestamp: String?
    let path: String?
}
