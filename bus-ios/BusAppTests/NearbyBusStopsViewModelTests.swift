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
        XCTAssertEqual(
            viewModel.userLocation,
            UserLocation(latitude: 1.2968, longitude: 103.853)
        )
        guard let mapRegion = viewModel.mapRegion else {
            XCTFail("Expected a map region after loading nearby stops")
            return
        }
        XCTAssertEqual(mapRegion.centerLatitude, 1.296825, accuracy: 0.000_001)
        XCTAssertEqual(mapRegion.centerLongitude, 103.853, accuracy: 0.000_001)
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

    func testDisplayModeAndMapSelectionAreOwnedByViewModel() async {
        let expectedStop = makeBusStop()
        let locationProvider = UserLocationProviderStub(
            result: .success(UserLocation(latitude: 1.2968, longitude: 103.853))
        )
        let apiClient = NearbyBusStopAPIClientStub(result: .success([expectedStop]))
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider
        )

        await viewModel.load()
        viewModel.setDisplayMode(.map)
        viewModel.selectBusStop(stopCode: expectedStop.stopCode)

        XCTAssertEqual(viewModel.displayMode, .map)
        XCTAssertEqual(viewModel.selectedStopCode, expectedStop.stopCode)
        XCTAssertEqual(viewModel.selectedBusStop, expectedStop)

        viewModel.selectBusStop(stopCode: "99999")

        XCTAssertNil(viewModel.selectedStopCode)
        XCTAssertNil(viewModel.selectedBusStop)
    }

    func testSearchMapAreaUsesMovedMapCenterAndReplacesStops() async {
        let initialStop = makeBusStop()
        let movedStop = makeBusStop(
            code: "02049",
            description: "Raffles Hotel",
            latitude: 1.2989,
            longitude: 103.855
        )
        let locationProvider = UserLocationProviderStub(
            result: .success(UserLocation(latitude: 1.2968, longitude: 103.853))
        )
        let apiClient = NearbyBusStopAPIClientStub(
            results: [.success([initialStop]), .success([movedStop])]
        )
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider,
            radiusMeters: 750,
            resultLimit: 5
        )

        await viewModel.load()
        viewModel.setDisplayMode(.map)
        viewModel.updateVisibleMapCenter(
            UserLocation(latitude: 1.2972, longitude: 103.853)
        )
        XCTAssertFalse(viewModel.canSearchMapArea)

        let movedCenter = UserLocation(latitude: 1.2988, longitude: 103.855)
        viewModel.updateVisibleMapCenter(movedCenter)
        XCTAssertTrue(viewModel.canSearchMapArea)

        await viewModel.searchPendingMapArea()

        XCTAssertEqual(viewModel.busStops, [movedStop])
        XCTAssertEqual(viewModel.lastSearchCenter, movedCenter)
        XCTAssertFalse(viewModel.canSearchMapArea)
        XCTAssertEqual(locationProvider.requestCount, 1)
        let request = await apiClient.lastRequest
        XCTAssertEqual(
            request,
            .init(
                latitude: 1.2988,
                longitude: 103.855,
                radiusMeters: 750,
                limit: 5
            )
        )
    }

    func testFailedMapAreaSearchPreservesExistingStopsAndCanRetry() async {
        let initialStop = makeBusStop()
        let locationProvider = UserLocationProviderStub(
            result: .success(UserLocation(latitude: 1.2968, longitude: 103.853))
        )
        let apiClient = NearbyBusStopAPIClientStub(
            results: [
                .success([initialStop]),
                .failure(BackendAPIError.server(statusCode: 502, message: "Try again later"))
            ]
        )
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider
        )

        await viewModel.load()
        viewModel.setDisplayMode(.map)
        viewModel.updateVisibleMapCenter(
            UserLocation(latitude: 1.2988, longitude: 103.855)
        )
        await viewModel.searchPendingMapArea()

        XCTAssertEqual(viewModel.busStops, [initialStop])
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.mapSearchMessage, "Try again later")
        XCTAssertTrue(viewModel.canSearchMapArea)
    }

    func testEmptyMapAreaSearchKeepsMapAvailableAndExplainsResult() async {
        let locationProvider = UserLocationProviderStub(
            result: .success(UserLocation(latitude: 1.2968, longitude: 103.853))
        )
        let apiClient = NearbyBusStopAPIClientStub(
            results: [.success([makeBusStop()]), .success([])]
        )
        let viewModel = NearbyBusStopsViewModel(
            apiClient: apiClient,
            locationProvider: locationProvider
        )

        await viewModel.load()
        viewModel.setDisplayMode(.map)
        viewModel.updateVisibleMapCenter(
            UserLocation(latitude: 1.2988, longitude: 103.855)
        )
        await viewModel.searchPendingMapArea()

        XCTAssertTrue(viewModel.busStops.isEmpty)
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(
            viewModel.mapSearchMessage,
            "No bus stops were found within 500 metres of this area."
        )
        XCTAssertNotNil(viewModel.mapRegion)
    }

    private func makeBusStop(
        code: String = "01012",
        description: String = "Hotel Grand Pacific",
        latitude: Double = 1.29685,
        longitude: Double = 103.853
    ) -> NearbyBusStop {
        NearbyBusStop(
            stopCode: code,
            roadName: "Victoria St",
            description: description,
            latitude: latitude,
            longitude: longitude,
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

    private var results: [Result<[NearbyBusStop], Error>]
    private(set) var lastRequest: Request?

    init(result: Result<[NearbyBusStop], Error>) {
        results = [result]
    }

    init(results: [Result<[NearbyBusStop], Error>]) {
        precondition(!results.isEmpty)
        self.results = results
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
        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}
