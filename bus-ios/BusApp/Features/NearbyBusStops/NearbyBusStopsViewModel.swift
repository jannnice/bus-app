import Foundation
import Observation

enum NearbyBusStopsDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case list
    case map

    var id: Self { self }
}

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
    private(set) var displayMode: NearbyBusStopsDisplayMode = .list
    private(set) var userLocation: UserLocation?
    private(set) var mapRegion: NearbyMapRegion?
    private(set) var selectedStopCode: String?

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

    var selectedBusStop: NearbyBusStop? {
        guard let selectedStopCode else {
            return nil
        }
        return busStops.first { $0.stopCode == selectedStopCode }
    }

    func setDisplayMode(_ displayMode: NearbyBusStopsDisplayMode) {
        self.displayMode = displayMode
    }

    func selectBusStop(stopCode: String?) {
        guard let stopCode else {
            selectedStopCode = nil
            return
        }

        selectedStopCode = busStops.contains { $0.stopCode == stopCode }
            ? stopCode
            : nil
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
            userLocation = location
            mapRegion = NearbyMapRegion.fitting(
                userLocation: location,
                busStops: results
            )
            if let selectedStopCode,
               !results.contains(where: { $0.stopCode == selectedStopCode }) {
                self.selectedStopCode = nil
            }
            state = results.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            state = previousState
            return
        } catch UserLocationError.permissionDenied {
            clearResults()
            state = .permissionDenied
        } catch UserLocationError.permissionRestricted {
            clearResults()
            state = .permissionRestricted
        } catch {
            clearResults()
            state = .failed(error.localizedDescription)
        }
    }

    private func clearResults() {
        busStops = []
        userLocation = nil
        mapRegion = nil
        selectedStopCode = nil
    }
}
