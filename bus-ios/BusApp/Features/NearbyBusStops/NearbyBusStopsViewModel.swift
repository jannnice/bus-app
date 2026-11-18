import Foundation
import Observation

enum NearbyBusStopsViewState: Equatable {
    case idle
    case requestingLocation
    case loadingStops
    case loaded
    case empty
    case permissionDenied
    case permissionRestricted
    case failed(String)
}

@MainActor
@Observable
final class NearbyBusStopsViewModel {
    private(set) var state: NearbyBusStopsViewState = .idle
    private(set) var busStops: [NearbyBusStop] = []

    private let apiClient: any NearbyBusStopAPIClient
    private let locationProvider: any UserLocationProvider
    private let radiusMeters: Int
    private let resultLimit: Int
    private var isRequestInFlight = false

    init(
        apiClient: any NearbyBusStopAPIClient,
        locationProvider: any UserLocationProvider,
        radiusMeters: Int = 500,
        resultLimit: Int = 20
    ) {
        self.apiClient = apiClient
        self.locationProvider = locationProvider
        self.radiusMeters = radiusMeters
        self.resultLimit = resultLimit
    }

    func load() async {
        guard !isRequestInFlight else {
            return
        }

        let previousState = state
        isRequestInFlight = true
        state = .requestingLocation
        defer { isRequestInFlight = false }

        do {
            let location = try await locationProvider.requestLocation()
            try Task.checkCancellation()

            state = .loadingStops
            let results = try await apiClient.nearbyBusStops(
                latitude: location.latitude,
                longitude: location.longitude,
                radiusMeters: radiusMeters,
                limit: resultLimit
            )
            try Task.checkCancellation()

            busStops = results
            state = results.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            state = previousState
            return
        } catch UserLocationError.permissionDenied {
            busStops = []
            state = .permissionDenied
        } catch UserLocationError.permissionRestricted {
            busStops = []
            state = .permissionRestricted
        } catch {
            busStops = []
            state = .failed(error.localizedDescription)
        }
    }
}
