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
}
