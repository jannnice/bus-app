import Foundation
import XCTest
@testable import BusApp

final class BusStopArrivalPreviewTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testBuilderShowsFourServicesWithEarliestNextArrivalsFirst() {
        let services = [
            makeService(number: "14", arrivals: [600]),
            makeService(number: "7", arrivals: [300, 120]),
            makeService(number: "36", arrivals: [240]),
            makeService(number: "2", arrivals: [60]),
            makeService(number: "10", arrivals: [180]),
            makeService(number: "99", arrivals: [nil])
        ]

        let previews = BusStopArrivalPreviewBuilder().previews(from: services)

        XCTAssertEqual(previews.map(\.serviceNo), ["2", "7", "10", "36"])
        XCTAssertEqual(
            previews.map(\.estimatedArrival),
            [60, 120, 180, 240].map(now.addingTimeInterval)
        )
    }

    func testBuilderHonoursCustomLimitAndStableServiceOrderingForTies() {
        let services = [
            makeService(number: "10", arrivals: [120]),
            makeService(number: "2", arrivals: [120]),
            makeService(number: "7", arrivals: [60])
        ]

        let previews = BusStopArrivalPreviewBuilder().previews(
            from: services,
            limit: 2
        )

        XCTAssertEqual(previews.map(\.serviceNo), ["7", "2"])
    }

    private func makeService(
        number: String,
        arrivals: [TimeInterval?]
    ) -> BusServiceArrival {
        BusServiceArrival(
            serviceNo: number,
            operator: "GAS",
            arrivals: arrivals.map { interval in
                BusArrivalPrediction(
                    originCode: "77009",
                    destinationCode: "77009",
                    estimatedArrival: interval.map(now.addingTimeInterval),
                    monitored: true,
                    latitude: nil,
                    longitude: nil,
                    visitNumber: 1,
                    load: .seatsAvailable,
                    wheelchairAccessible: true,
                    type: .singleDeck
                )
            }
        )
    }
}
