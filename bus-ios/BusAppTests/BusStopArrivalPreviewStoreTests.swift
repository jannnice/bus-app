import Foundation
import XCTest
@testable import BusApp

@MainActor
final class BusStopArrivalPreviewStoreTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testLoadPublishesSortedPreviewState() async {
        let client = ArrivalPreviewAPIClientStub(
            results: [
                .success(
                    BusArrivalResponse(
                        stopCode: "83139",
                        services: [
                            makeService(number: "15", secondsUntilArrival: 300),
                            makeService(number: "14", secondsUntilArrival: 120)
                        ]
                    )
                )
            ]
        )
        let store = makeStore(client: client)

        await store.load(stopCode: "83139")

        XCTAssertEqual(
            store.state(for: "83139"),
            .loaded([
                BusStopArrivalPreview(
                    serviceNo: "14",
                    estimatedArrival: now.addingTimeInterval(120)
                ),
                BusStopArrivalPreview(
                    serviceNo: "15",
                    estimatedArrival: now.addingTimeInterval(300)
                )
            ])
        )
        let requestedStopCodes = await client.requestedStopCodes
        XCTAssertEqual(requestedStopCodes, ["83139"])
    }

    func testFreshPreviewSkipsDuplicateRequestUnlessForced() async {
        let response = BusArrivalResponse(
            stopCode: "83139",
            services: [makeService(number: "15", secondsUntilArrival: 300)]
        )
        let client = ArrivalPreviewAPIClientStub(
            results: [.success(response), .success(response)]
        )
        let store = makeStore(client: client)

        await store.load(stopCode: "83139")
        await store.load(stopCode: "83139")
        var requestedStopCodes = await client.requestedStopCodes
        XCTAssertEqual(requestedStopCodes, ["83139"])

        await store.load(stopCode: "83139", force: true)
        requestedStopCodes = await client.requestedStopCodes
        XCTAssertEqual(requestedStopCodes, ["83139", "83139"])
    }

    func testLoadPublishesEmptyAndFailureStates() async {
        let client = ArrivalPreviewAPIClientStub(
            results: [
                .success(BusArrivalResponse(stopCode: "83139", services: [])),
                .failure(BackendAPIError.server(statusCode: 502, message: "Try again later"))
            ]
        )
        let store = makeStore(client: client)

        await store.load(stopCode: "83139")
        XCTAssertEqual(store.state(for: "83139"), .empty)

        await store.load(stopCode: "01012", force: true)
        XCTAssertEqual(store.state(for: "01012"), .failed("Try again later"))
    }

    func testAutoRefreshUsesTwentySecondInterval() async {
        let client = ArrivalPreviewAPIClientStub(
            results: [
                .success(BusArrivalResponse(stopCode: "83139", services: []))
            ]
        )
        let sleepRecorder = ArrivalPreviewSleepRecorder()
        let store = BusStopArrivalPreviewStore(
            apiClient: client,
            now: { self.now },
            sleep: { duration in
                await sleepRecorder.record(duration)
                throw CancellationError()
            }
        )

        await store.runAutoRefresh(stopCode: "83139")

        let durations = await sleepRecorder.durations
        XCTAssertEqual(durations, [.seconds(20)])
    }

    private func makeStore(
        client: ArrivalPreviewAPIClientStub
    ) -> BusStopArrivalPreviewStore {
        BusStopArrivalPreviewStore(
            apiClient: client,
            now: { self.now }
        )
    }

    private func makeService(
        number: String,
        secondsUntilArrival: TimeInterval
    ) -> BusServiceArrival {
        BusServiceArrival(
            serviceNo: number,
            operator: "GAS",
            arrivals: [
                BusArrivalPrediction(
                    originCode: "77009",
                    destinationCode: "77009",
                    estimatedArrival: now.addingTimeInterval(secondsUntilArrival),
                    monitored: true,
                    latitude: nil,
                    longitude: nil,
                    visitNumber: 1,
                    load: .seatsAvailable,
                    wheelchairAccessible: true,
                    type: .singleDeck
                )
            ]
        )
    }
}

private actor ArrivalPreviewAPIClientStub: BusArrivalAPIClient {
    private var results: [Result<BusArrivalResponse, Error>]
    private(set) var requestedStopCodes: [String] = []

    init(results: [Result<BusArrivalResponse, Error>]) {
        precondition(!results.isEmpty)
        self.results = results
    }

    func arrivals(for stopCode: String) async throws -> BusArrivalResponse {
        requestedStopCodes.append(stopCode)
        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}

private actor ArrivalPreviewSleepRecorder {
    private(set) var durations: [Duration] = []

    func record(_ duration: Duration) {
        durations.append(duration)
    }
}
