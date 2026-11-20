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
    let centerLatitude: Double
    let centerLongitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double

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
