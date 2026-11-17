import XCTest
@testable import BusApp

final class BusStopDecodingTests: XCTestCase {
    func testDecodesTheBackendBusStopShape() throws {
        let data = Data(
            """
            {
              "stopCode": "01012",
              "roadName": "Victoria St",
              "description": "Hotel Grand Pacific",
              "latitude": 1.29685,
              "longitude": 103.853
            }
            """.utf8
        )

        let busStop = try JSONDecoder().decode(BusStop.self, from: data)

        XCTAssertEqual(busStop.stopCode, "01012")
        XCTAssertEqual(busStop.description, "Hotel Grand Pacific")
        XCTAssertEqual(busStop.latitude, 1.29685)
    }
}
