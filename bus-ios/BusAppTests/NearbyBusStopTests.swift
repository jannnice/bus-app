import Foundation
import XCTest
@testable import BusApp

final class NearbyBusStopTests: XCTestCase {
    func testDecodesNearbyBusStopAndDistance() throws {
        let data = Data(
            """
            {
              "stopCode": "01012",
              "roadName": "Victoria St",
              "description": "Hotel Grand Pacific",
              "latitude": 1.29685,
              "longitude": 103.853,
              "distanceMeters": 85
            }
            """.utf8
        )

        let busStop = try JSONDecoder().decode(NearbyBusStop.self, from: data)

        XCTAssertEqual(busStop.stopCode, "01012")
        XCTAssertEqual(busStop.distanceMeters, 85)
        XCTAssertEqual(busStop.busStop.description, "Hotel Grand Pacific")
    }

    func testFormatsDistancesInMetersAndKilometres() {
        let formatter = DistanceFormatter()

        XCTAssertEqual(formatter.string(for: 85), "85 m")
        XCTAssertEqual(formatter.string(for: 1_200), "1.2 km")
    }

    func testCarouselOrdersFavoritesFirstWithoutChangingOrderWithinGroups() {
        let closestStop = makeBusStop(code: "01012", distanceMeters: 50)
        let firstFavorite = makeBusStop(code: "01013", distanceMeters: 100)
        let secondFavorite = makeBusStop(code: "01014", distanceMeters: 150)
        let furthestStop = makeBusStop(code: "01015", distanceMeters: 200)

        let orderedStops = NearbyBusStopCarouselOrdering.favoritesFirst(
            [closestStop, firstFavorite, secondFavorite, furthestStop],
            favoriteStopCodes: [firstFavorite.stopCode, secondFavorite.stopCode]
        )

        XCTAssertEqual(
            orderedStops.map(\.stopCode),
            ["01013", "01014", "01012", "01015"]
        )
    }

    private func makeBusStop(code: String, distanceMeters: Int) -> NearbyBusStop {
        NearbyBusStop(
            stopCode: code,
            roadName: "Victoria St",
            description: "Bus Stop \(code)",
            latitude: 1.2968,
            longitude: 103.853,
            distanceMeters: distanceMeters
        )
    }
}
