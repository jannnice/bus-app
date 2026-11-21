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
    private(set) var displayMode: NearbyBusStopsDisplayMode = .map
    private(set) var userLocation: UserLocation?
    private(set) var mapRegion: NearbyMapRegion?
    private(set) var selectedStopCode: String?
    private(set) var lastSearchCenter: UserLocation?
    private(set) var pendingMapCenter: UserLocation?
    private(set) var isSearchingMapArea = false
    private(set) var mapSearchMessage: String?

    private let apiClient: any NearbyBusStopAPIClient
    private let locationProvider: any UserLocationProvider
    private let radiusMeters: Int
    private let resultLimit: Int
    private let mapSearchMovementThresholdMeters: Double
    private var isRequestInFlight = false

    init(
        apiClient: any NearbyBusStopAPIClient,
        locationProvider: any UserLocationProvider,
        radiusMeters: Int = 500,
        resultLimit: Int = 20,
        mapSearchMovementThresholdMeters: Double = 100
    ) {
        self.apiClient = apiClient
        self.locationProvider = locationProvider
        self.radiusMeters = radiusMeters
        self.resultLimit = resultLimit
        self.mapSearchMovementThresholdMeters = mapSearchMovementThresholdMeters
    }

    var selectedBusStop: NearbyBusStop? {
        guard let selectedStopCode else {
            return nil
        }
        return busStops.first { $0.stopCode == selectedStopCode }
    }

    var canSearchMapArea: Bool {
        pendingMapCenter != nil && !isSearchingMapArea
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

    func updateVisibleMapCenter(_ center: UserLocation) {
        guard displayMode == .map,
              let lastSearchCenter,
              NearbyMapSearchPolicy.shouldOfferSearch(
                  from: lastSearchCenter,
                  to: center,
                  minimumDistanceMeters: mapSearchMovementThresholdMeters
              ) else {
            pendingMapCenter = nil
            return
        }

        pendingMapCenter = center
    }

    func searchPendingMapArea() async {
        guard state == .loaded,
              let searchCenter = pendingMapCenter,
              !isRequestInFlight else {
            return
        }

        isRequestInFlight = true
        isSearchingMapArea = true
        mapSearchMessage = nil
        defer {
            isRequestInFlight = false
            isSearchingMapArea = false
        }

        do {
            let results = try await apiClient.nearbyBusStops(
                latitude: searchCenter.latitude,
                longitude: searchCenter.longitude,
                radiusMeters: radiusMeters,
                limit: resultLimit
            )
            try Task.checkCancellation()

            busStops = results
            lastSearchCenter = searchCenter
            if pendingMapCenter == searchCenter {
                pendingMapCenter = nil
            }
            mapRegion = NearbyMapRegion.fitting(
                userLocation: searchCenter,
                busStops: results
            )
            if let selectedStopCode,
               !results.contains(where: { $0.stopCode == selectedStopCode }) {
                self.selectedStopCode = nil
            }
            if results.isEmpty {
                mapSearchMessage = "No bus stops were found within 500 metres of this area."
            }
        } catch is CancellationError {
            return
        } catch {
            mapSearchMessage = error.localizedDescription
        }
    }

    func dismissMapSearchMessage() {
        mapSearchMessage = nil
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
            lastSearchCenter = location
            pendingMapCenter = nil
            mapSearchMessage = nil
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
        lastSearchCenter = nil
        pendingMapCenter = nil
        mapSearchMessage = nil
    }
}
