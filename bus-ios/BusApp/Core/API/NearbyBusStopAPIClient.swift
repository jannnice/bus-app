import Foundation

protocol NearbyBusStopAPIClient: Sendable {
    func nearbyBusStops(
        latitude: Double,
        longitude: Double,
        radiusMeters: Int,
        limit: Int
    ) async throws -> [NearbyBusStop]
}
