import XCTest
@testable import BusApp

final class NearbyMapRegionTests: XCTestCase {
    func testAnnotationMapsStopDetailsAndFavouriteState() {
        let busStop = makeBusStop(latitude: 1.29685, longitude: 103.853)

        let annotation = NearbyMapAnnotation(busStop: busStop, isFavorite: true)

        XCTAssertEqual(annotation.id, "01012")
        XCTAssertEqual(annotation.title, "Hotel Grand Pacific")
        XCTAssertEqual(annotation.latitude, 1.29685)
        XCTAssertEqual(annotation.longitude, 103.853)
        XCTAssertEqual(annotation.distanceMeters, 85)
        XCTAssertTrue(annotation.isFavorite)
    }

    func testFittingRegionContainsUserAndEveryBusStopWithPadding() {
        let userLocation = UserLocation(latitude: 1.0, longitude: 103.0)
        let busStops = [
            makeBusStop(latitude: 1.004, longitude: 103.006),
            makeBusStop(latitude: 0.998, longitude: 102.996)
        ]

        let region = NearbyMapRegion.fitting(
            userLocation: userLocation,
            busStops: busStops
        )

        XCTAssertEqual(region.centerLatitude, 1.001, accuracy: 0.000_001)
        XCTAssertEqual(region.centerLongitude, 103.001, accuracy: 0.000_001)
        XCTAssertEqual(region.latitudeDelta, 0.0084, accuracy: 0.000_001)
        XCTAssertEqual(region.longitudeDelta, 0.014, accuracy: 0.000_001)
    }

    func testFittingRegionUsesMinimumSpanForOneLocation() {
        let region = NearbyMapRegion.fitting(
            userLocation: UserLocation(latitude: 1.2968, longitude: 103.853),
            busStops: []
        )

        XCTAssertEqual(region.centerLatitude, 1.2968, accuracy: 0.000_001)
        XCTAssertEqual(region.centerLongitude, 103.853, accuracy: 0.000_001)
        XCTAssertEqual(region.latitudeDelta, 0.006, accuracy: 0.000_001)
        XCTAssertEqual(region.longitudeDelta, 0.006, accuracy: 0.000_001)
    }

    func testSearchPolicyIgnoresSmallCameraMovements() {
        let previousCenter = UserLocation(latitude: 1.2968, longitude: 103.853)
        let nearbyCenter = UserLocation(latitude: 1.2972, longitude: 103.853)

        XCTAssertFalse(
            NearbyMapSearchPolicy.shouldOfferSearch(
                from: previousCenter,
                to: nearbyCenter
            )
        )
    }

    func testSearchPolicyOffersSearchAfterMeaningfulCameraMovement() {
        let previousCenter = UserLocation(latitude: 1.2968, longitude: 103.853)
        let movedCenter = UserLocation(latitude: 1.2988, longitude: 103.855)

        XCTAssertTrue(
            NearbyMapSearchPolicy.shouldOfferSearch(
                from: previousCenter,
                to: movedCenter
            )
        )
    }

    private func makeBusStop(latitude: Double, longitude: Double) -> NearbyBusStop {
        NearbyBusStop(
            stopCode: "01012",
            roadName: "Victoria St",
            description: "Hotel Grand Pacific",
            latitude: latitude,
            longitude: longitude,
            distanceMeters: 85
        )
    }
}
