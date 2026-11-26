import Foundation
import XCTest
@testable import BusApp

@MainActor
final class BusWidgetTests: XCTestCase {
    private let stop = BusStop(
        stopCode: "01012", roadName: "Victoria St", description: "Hotel Grand Pacific",
        latitude: 1.29685, longitude: 103.853
    )
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testFavoriteMigrationPreservesOrderAndDoesNotRestoreDeletedFavorites() throws {
        let legacySuite = "widget-tests.legacy.\(UUID())"
        let sharedSuite = "widget-tests.shared.\(UUID())"
        let legacy = try XCTUnwrap(UserDefaults(suiteName: legacySuite))
        let shared = try XCTUnwrap(UserDefaults(suiteName: sharedSuite))
        defer {
            legacy.removePersistentDomain(forName: legacySuite)
            shared.removePersistentDomain(forName: sharedSuite)
        }
        let second = BusStop(stopCode: "01013", roadName: "Victoria St", description: "Second stop",
                             latitude: 1.297, longitude: 103.853)
        let ordered = [second, stop]
        try UserDefaultsFavoriteBusStopStorage(userDefaults: legacy).save(ordered)

        UserDefaultsFavoriteBusStopStorage.migrateFavorites(from: legacy, to: shared)
        let data = BusWidgetData(defaults: shared)
        XCTAssertEqual(try data.favorites(), ordered)

        try UserDefaultsFavoriteBusStopStorage(userDefaults: shared).save([])
        UserDefaultsFavoriteBusStopStorage.migrateFavorites(from: legacy, to: shared)
        XCTAssertEqual(try data.favorites(), [])
        XCTAssertEqual(try UserDefaultsFavoriteBusStopStorage(userDefaults: legacy).load(), ordered)
    }

    func testDeepLinkRoundTripsStopCodeAndRejectsMalformedPaths() throws {
        let route = BusWidgetLink.arrivals(stop.stopCode)
        XCTAssertEqual(BusWidgetLink(url: try XCTUnwrap(route.url)), route)
        XCTAssertEqual(BusWidgetLink(url: try XCTUnwrap(BusWidgetLink.favorites.url)), .favorites)
        for value in ["https://arrivals/01012", "busapp://arrivals/01012/extra",
                      "busapp://arrivals/1012", "busapp://arrivals/01012?extra=1"] {
            XCTAssertNil(BusWidgetLink(url: try XCTUnwrap(URL(string: value))))
        }
    }

    func testSnapshotSkipsPastPredictionsAndExpires() {
        let predictions = [-20.0, 60.0, 600.0].map { seconds in
            BusArrivalPrediction(originCode: stop.stopCode, destinationCode: stop.stopCode,
                                 estimatedArrival: now.addingTimeInterval(seconds), monitored: true,
                                 latitude: nil, longitude: nil, visitNumber: nil,
                                 load: .unknown, wheelchairAccessible: false, type: .unknown)
        }
        let response = BusArrivalResponse(stopCode: stop.stopCode, services: [
            BusServiceArrival(serviceNo: "7", operator: "SBST", arrivals: Array(predictions.prefix(2))),
            BusServiceArrival(serviceNo: "2", operator: "SBST", arrivals: [predictions[2]])
        ])
        let snapshot = BusWidgetSnapshot(response: response, fetchedAt: now)
        XCTAssertEqual(snapshot.arrivals.map(\.serviceNo), ["7", "2"])
        XCTAssertEqual(snapshot.predictions(at: now.addingTimeInterval(90)).map(\.serviceNo), ["2"])
        XCTAssertTrue(snapshot.isExpired(at: now.addingTimeInterval(300)))
        XCTAssertTrue(snapshot.predictions(at: now.addingTimeInterval(300)).isEmpty)
    }

    func testManualRefreshFailureKeepsCachedSnapshotAndTimelineSkipsDuplicateRequest() async throws {
        let suite = "widget-tests.refresh.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try UserDefaultsFavoriteBusStopStorage(userDefaults: defaults).save([stop])
        let data = BusWidgetData(defaults: defaults)
        let cached = BusWidgetSnapshot(response: .init(stopCode: stop.stopCode, services: []),
                                       fetchedAt: now.addingTimeInterval(-90))
        data.save(cached, for: stop.stopCode, fromApp: true)

        let client = OfflineArrivalsClient()
        let date = now
        let loader = WidgetArrivalLoader(client: client, openData: {
            UserDefaults(suiteName: suite).map { BusWidgetData(defaults: $0) }
        }, now: { date })
        await loader.refresh(stopCode: stop.stopCode, manual: true)
        await loader.refresh(stopCode: stop.stopCode, manual: false)
        await loader.refresh(stopCode: stop.stopCode, manual: true)

        let calls = await client.calls
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(data.snapshot(for: stop.stopCode), cached)
        XCTAssertEqual(data.attempt(for: stop.stopCode)?.failure, .offline)
    }
}

private actor OfflineArrivalsClient: BusArrivalAPIClient {
    private(set) var calls = 0

    func arrivals(for stopCode: String) async throws -> BusArrivalResponse {
        calls += 1
        throw URLError(.notConnectedToInternet)
    }
}
