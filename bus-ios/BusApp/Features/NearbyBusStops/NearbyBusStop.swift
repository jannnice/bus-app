import Foundation

struct NearbyBusStop: Decodable, Equatable, Identifiable, Sendable {
    let stopCode: String
    let roadName: String
    let description: String
    let latitude: Double
    let longitude: Double
    let distanceMeters: Int

    var id: String { stopCode }

    var busStop: BusStop {
        BusStop(
            stopCode: stopCode,
            roadName: roadName,
            description: description,
            latitude: latitude,
            longitude: longitude
        )
    }
}

enum NearbyBusStopCarouselOrdering {
    static func favoritesFirst(
        _ busStops: [NearbyBusStop],
        favoriteStopCodes: Set<String>
    ) -> [NearbyBusStop] {
        let favorites = busStops.filter { favoriteStopCodes.contains($0.stopCode) }
        let remainingStops = busStops.filter { !favoriteStopCodes.contains($0.stopCode) }
        return favorites + remainingStops
    }
}
