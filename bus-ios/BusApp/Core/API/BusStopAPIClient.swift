import Foundation

protocol BusStopAPIClient: Sendable {
    func searchBusStops(query: String, limit: Int) async throws -> [BusStop]
}
