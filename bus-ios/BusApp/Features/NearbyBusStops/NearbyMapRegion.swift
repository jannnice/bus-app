import Foundation

struct NearbyMapAnnotation: Equatable, Identifiable, Sendable {
    let stopCode: String
    let title: String
    let latitude: Double
    let longitude: Double
    let distanceMeters: Int
    let isFavorite: Bool

    var id: String { stopCode }

    init(busStop: NearbyBusStop, isFavorite: Bool) {
        stopCode = busStop.stopCode
        title = busStop.description
        latitude = busStop.latitude
        longitude = busStop.longitude
        distanceMeters = busStop.distanceMeters
        self.isFavorite = isFavorite
    }
}

struct NearbyMapRegion: Equatable, Sendable {
    // About 1.1 km at Singapore's latitude, leaving useful context around a 500 m search radius.
    static let defaultNearbySpan = 0.01

    let centerLatitude: Double
    let centerLongitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double

    static func centered(
        on userLocation: UserLocation,
        span: Double = NearbyMapRegion.defaultNearbySpan
    ) -> NearbyMapRegion {
        NearbyMapRegion(
            centerLatitude: userLocation.latitude,
            centerLongitude: userLocation.longitude,
            latitudeDelta: span,
            longitudeDelta: span
        )
    }

    static func fitting(
        userLocation: UserLocation,
        busStops: [NearbyBusStop],
        minimumSpan: Double = 0.006,
        paddingFactor: Double = 1.4
    ) -> NearbyMapRegion {
        let latitudes = [userLocation.latitude] + busStops.map(\.latitude)
        let longitudes = [userLocation.longitude] + busStops.map(\.longitude)

        let minimumLatitude = latitudes.min() ?? userLocation.latitude
        let maximumLatitude = latitudes.max() ?? userLocation.latitude
        let minimumLongitude = longitudes.min() ?? userLocation.longitude
        let maximumLongitude = longitudes.max() ?? userLocation.longitude

        return NearbyMapRegion(
            centerLatitude: (minimumLatitude + maximumLatitude) / 2,
            centerLongitude: (minimumLongitude + maximumLongitude) / 2,
            latitudeDelta: max(minimumSpan, (maximumLatitude - minimumLatitude) * paddingFactor),
            longitudeDelta: max(minimumSpan, (maximumLongitude - minimumLongitude) * paddingFactor)
        )
    }
}

enum NearbyMapSearchPolicy {
    static func shouldOfferSearch(
        from previousCenter: UserLocation,
        to visibleCenter: UserLocation,
        minimumDistanceMeters: Double = 100
    ) -> Bool {
        distanceMeters(from: previousCenter, to: visibleCenter) >= minimumDistanceMeters
    }

    private static func distanceMeters(
        from start: UserLocation,
        to end: UserLocation
    ) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let latitudeDelta = degreesToRadians(end.latitude - start.latitude)
        let longitudeDelta = degreesToRadians(end.longitude - start.longitude)
        let startLatitude = degreesToRadians(start.latitude)
        let endLatitude = degreesToRadians(end.latitude)

        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        let clampedHaversine = min(1, max(0, haversine))
        let angularDistance = 2 * atan2(
            sqrt(clampedHaversine),
            sqrt(1 - clampedHaversine)
        )

        return earthRadiusMeters * angularDistance
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
