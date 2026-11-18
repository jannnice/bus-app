import Foundation

protocol BusArrivalAPIClient: Sendable {
    func arrivals(for stopCode: String) async throws -> BusArrivalResponse
}
