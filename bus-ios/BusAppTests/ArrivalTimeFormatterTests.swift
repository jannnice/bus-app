import Foundation
import XCTest
@testable import BusApp

final class ArrivalTimeFormatterTests: XCTestCase {
    private let formatter = ArrivalTimeFormatter()
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testMissingPredictionDisplaysDash() {
        XCTAssertEqual(formatter.string(for: nil, relativeTo: now), "—")
    }

    func testPastAndSubMinutePredictionsDisplayArr() {
        XCTAssertEqual(
            formatter.string(for: now.addingTimeInterval(-30), relativeTo: now),
            "Arr"
        )
        XCTAssertEqual(
            formatter.string(for: now.addingTimeInterval(59), relativeTo: now),
            "Arr"
        )
    }

    func testFuturePredictionDisplaysWholeMinutes() {
        XCTAssertEqual(
            formatter.string(for: now.addingTimeInterval(185), relativeTo: now),
            "3 min"
        )
    }
}
