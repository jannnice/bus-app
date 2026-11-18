import Foundation
import XCTest
@testable import BusApp

@MainActor
final class BusArrivalViewModelTests: XCTestCase {
    func testLoadPublishesServices() async {
        let service = makeService()
        let client = BusArrivalAPIClientStub(
            result: .success(BusArrivalResponse(stopCode: "83139", services: [service]))
        )
        let viewModel = BusArrivalViewModel(stopCode: "83139", apiClient: client)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.services, [service])
        let requestedStopCodes = await client.requestedStopCodes
        XCTAssertEqual(requestedStopCodes, ["83139"])
    }

    func testLoadPublishesEmptyState() async {
        let client = BusArrivalAPIClientStub(
            result: .success(BusArrivalResponse(stopCode: "83139", services: []))
        )
        let viewModel = BusArrivalViewModel(stopCode: "83139", apiClient: client)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertTrue(viewModel.services.isEmpty)
    }

    func testLoadPublishesFailureAndClearsServices() async {
        let client = BusArrivalAPIClientStub(
            result: .failure(
                BackendAPIError.server(statusCode: 502, message: "Try again later")
            )
        )
        let viewModel = BusArrivalViewModel(stopCode: "83139", apiClient: client)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed("Try again later"))
        XCTAssertTrue(viewModel.services.isEmpty)
    }

    func testCancellationDoesNotBecomeAnError() async {
        let client = BusArrivalAPIClientStub(result: .failure(CancellationError()))
        let viewModel = BusArrivalViewModel(stopCode: "83139", apiClient: client)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loading)
    }

    func testAutoRefreshUsesTheTwentySecondBackendInterval() async {
        let client = BusArrivalAPIClientStub(
            result: .success(BusArrivalResponse(stopCode: "83139", services: []))
        )
        let sleepRecorder = SleepRecorder()
        let viewModel = BusArrivalViewModel(
            stopCode: "83139",
            apiClient: client,
            sleep: { duration in
                await sleepRecorder.record(duration)
                throw CancellationError()
            }
        )

        await viewModel.runAutoRefresh()

        let recordedDurations = await sleepRecorder.durations
        XCTAssertEqual(recordedDurations, [.seconds(20)])
    }

    private func makeService() -> BusServiceArrival {
        BusServiceArrival(
            serviceNo: "15",
            operator: "GAS",
            arrivals: []
        )
    }
}

private actor SleepRecorder {
    private(set) var durations: [Duration] = []

    func record(_ duration: Duration) {
        durations.append(duration)
    }
}

private actor BusArrivalAPIClientStub: BusArrivalAPIClient {
    private let result: Result<BusArrivalResponse, Error>
    private(set) var requestedStopCodes: [String] = []

    init(result: Result<BusArrivalResponse, Error>) {
        self.result = result
    }

    func arrivals(for stopCode: String) async throws -> BusArrivalResponse {
        requestedStopCodes.append(stopCode)
        return try result.get()
    }
}
