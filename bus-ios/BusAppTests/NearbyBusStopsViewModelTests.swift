import Foundation
import XCTest
@testable import BusApp

@MainActor
final class NearbyBusStopsViewModelTests: XCTestCase {
    func testLoadRequestsLocationAndPublishesNearbyStops() async {
        let expectedStop = makeBusStop()
        let locationProvider = UserLocationProviderStub(
            result: .success(UserLocation(latitude: 1.2968, longitude: 103.853))
        )
        let apiClient = NearbyBusStopAPIClientStub(result: .success([expectedStop]))
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider,
            radiusMeters: 750,
            resultLimit: 5
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.busStops, [expectedStop])
        XCTAssertEqual(locationProvider.requestCount, 1)
        let request = await apiClient.lastRequest
        XCTAssertEqual(
            request,
            .init(
                latitude: 1.2968,
                longitude: 103.853,
                radiusMeters: 750,
                limit: 5
            )
        )
    }

    func testLoadPublishesEmptyState() async {
        let locationProvider = UserLocationProviderStub(
            result: .success(UserLocation(latitude: 1.2968, longitude: 103.853))
        )
        let apiClient = NearbyBusStopAPIClientStub(result: .success([]))
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertTrue(viewModel.busStops.isEmpty)
    }

    func testDeniedLocationPublishesPermissionStateWithoutCallingBackend() async {
        let locationProvider = UserLocationProviderStub(
            result: .failure(UserLocationError.permissionDenied)
        )
        let apiClient = NearbyBusStopAPIClientStub(result: .success([]))
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .permissionDenied)
        let request = await apiClient.lastRequest
        XCTAssertNil(request)
    }

    func testRestrictedLocationPublishesRestrictedState() async {
        let locationProvider = UserLocationProviderStub(
            result: .failure(UserLocationError.permissionRestricted)
        )
        let apiClient = NearbyBusStopAPIClientStub(result: .success([]))
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .permissionRestricted)
    }

    func testBackendFailurePublishesRetryableError() async {
        let locationProvider = UserLocationProviderStub(
            result: .success(UserLocation(latitude: 1.2968, longitude: 103.853))
        )
        let apiClient = NearbyBusStopAPIClientStub(
            result: .failure(
                BackendAPIError.server(statusCode: 502, message: "Try again later")
            )
        )
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed("Try again later"))
        XCTAssertTrue(viewModel.busStops.isEmpty)
    }

    func testCancellationRestoresThePreviousState() async {
        let locationProvider = UserLocationProviderStub(
            result: .failure(CancellationError())
        )
        let apiClient = NearbyBusStopAPIClientStub(result: .success([]))
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .idle)
        let request = await apiClient.lastRequest
        XCTAssertNil(request)
    }

    private func makeBusStop() -> NearbyBusStop {
        NearbyBusStop(
            stopCode: "01012",
            roadName: "Victoria St",
            description: "Hotel Grand Pacific",
            latitude: 1.29685,
            longitude: 103.853,
            distanceMeters: 85
        )
    }
}

@MainActor
private final class UserLocationProviderStub: UserLocationProvider {
    private let result: Result<UserLocation, Error>
    private(set) var requestCount = 0

    init(result: Result<UserLocation, Error>) {
        self.result = result
    }

    func requestLocation() async throws -> UserLocation {
        requestCount += 1
        return try result.get()
    }
}

private actor NearbyBusStopAPIClientStub: NearbyBusStopAPIClient {
    struct Request: Equatable {
        let latitude: Double
        let longitude: Double
        let radiusMeters: Int
        let limit: Int
    }

    private let result: Result<[NearbyBusStop], Error>
    private(set) var lastRequest: Request?

    init(result: Result<[NearbyBusStop], Error>) {
        self.result = result
    }

    func nearbyBusStops(
        latitude: Double,
        longitude: Double,
        radiusMeters: Int,
        limit: Int
    ) async throws -> [NearbyBusStop] {
        lastRequest = Request(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            limit: limit
        )
        return try result.get()
    }
}
