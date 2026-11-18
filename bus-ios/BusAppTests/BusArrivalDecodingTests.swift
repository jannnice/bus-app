import Foundation
import XCTest
@testable import BusApp

final class BusArrivalDecodingTests: XCTestCase {
    func testDecodesTheBackendArrivalShapeAndSingaporeOffset() throws {
        let data = Data(
            """
            {
              "stopCode": "83139",
              "services": [{
                "serviceNo": "15",
                "operator": "GAS",
                "arrivals": [{
                  "originCode": "77009",
                  "destinationCode": "77009",
                  "estimatedArrival": "2026-11-16T22:19:59+08:00",
                  "monitored": true,
                  "latitude": 1.3154918333333334,
                  "longitude": 103.9059125,
                  "visitNumber": 1,
                  "load": "SEATS_AVAILABLE",
                  "wheelchairAccessible": true,
                  "type": "DOUBLE_DECK"
                }, {
                  "originCode": "77009",
                  "destinationCode": "77009",
                  "estimatedArrival": null,
                  "monitored": false,
                  "latitude": null,
                  "longitude": null,
                  "visitNumber": null,
                  "load": "UNKNOWN",
                  "wheelchairAccessible": false,
                  "type": "UNKNOWN"
                }]
              }]
            }
            """.utf8
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(BusArrivalResponse.self, from: data)

        XCTAssertEqual(response.stopCode, "83139")
        XCTAssertEqual(response.services.first?.serviceNo, "15")
        XCTAssertEqual(response.services.first?.operator, "GAS")
        XCTAssertEqual(response.services.first?.arrivals.count, 2)

        let firstArrival = try XCTUnwrap(response.services.first?.arrivals.first)
        XCTAssertEqual(firstArrival.load, .seatsAvailable)
        XCTAssertEqual(firstArrival.type, .doubleDeck)
        XCTAssertTrue(firstArrival.wheelchairAccessible)
        XCTAssertEqual(firstArrival.latitude, 1.3154918333333334)
        XCTAssertEqual(firstArrival.visitNumber, 1)

        let expectedDate = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-11-16T22:19:59+08:00")
        )
        XCTAssertEqual(firstArrival.estimatedArrival, expectedDate)
        XCTAssertNil(response.services.first?.arrivals.last?.estimatedArrival)
        XCTAssertNil(response.services.first?.arrivals.last?.latitude)
    }
}
