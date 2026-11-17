import Foundation
import XCTest
@testable import BusApp

@MainActor
final class BusStopSearchViewModelTests: XCTestCase {
    func testSearchTrimsTheQueryAndPublishesResults() async {
        let expectedBusStop = BusStop(
            stopCode: "01012",
            roadName: "Victoria St",
            description: "Hotel Grand Pacific",
            latitude: 1.29685,
            longitude: 103.853
        )
        let client = BusStopAPIClientStub(result: .success([expectedBusStop]))
        let viewModel = BusStopSearchViewModel(apiClient: client, resultLimit: 10)
        viewModel.query = "  grand  "

        await viewModel.search()

        XCTAssertEqual(viewModel.busStops, [expectedBusStop])
        XCTAssertTrue(viewModel.hasSearched)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        let lastRequest = await client.lastRequest
        XCTAssertEqual(lastRequest, .init(query: "grand", limit: 10))
    }

    func testSearchPublishesAnErrorAndClearsStaleResults() async {
        let client = BusStopAPIClientStub(
            result: .failure(BackendAPIError.server(statusCode: 502, message: "Try again later"))
        )
        let viewModel = BusStopSearchViewModel(apiClient: client)
        viewModel.query = "grand"

        await viewModel.search()

        XCTAssertTrue(viewModel.busStops.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Try again later")
        XCTAssertTrue(viewModel.hasSearched)
    }

    func testBlankQueryDoesNotCallTheBackend() async {
        let client = BusStopAPIClientStub(result: .success([]))
        let viewModel = BusStopSearchViewModel(apiClient: client)
        viewModel.query = "   "

        await viewModel.search()

        let lastRequest = await client.lastRequest
        XCTAssertNil(lastRequest)
        XCTAssertFalse(viewModel.hasSearched)
    }
}

private actor BusStopAPIClientStub: BusStopAPIClient {
    struct Request: Equatable {
        let query: String
        let limit: Int
    }

    private let result: Result<[BusStop], Error>
    private(set) var lastRequest: Request?

    init(result: Result<[BusStop], Error>) {
        self.result = result
    }

    func searchBusStops(query: String, limit: Int) async throws -> [BusStop] {
        lastRequest = Request(query: query, limit: limit)
        return try result.get()
    }
}
