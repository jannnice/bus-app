import Foundation
import Observation

enum BusStopArrivalPreviewState: Equatable {
    case idle
    case loading
    case loaded([BusStopArrivalPreview])
    case empty
    case failed(String)
}

@MainActor
@Observable
final class BusStopArrivalPreviewStore {
    private(set) var states: [String: BusStopArrivalPreviewState] = [:]

    private let apiClient: any BusArrivalAPIClient
    private let builder: BusStopArrivalPreviewBuilder
    private let refreshInterval: Duration
    private let freshnessInterval: TimeInterval
    private let now: () -> Date
    private let sleep: @Sendable (Duration) async throws -> Void
    private var lastUpdated: [String: Date] = [:]
    private var requestsInFlight: Set<String> = []

    init(
        apiClient: any BusArrivalAPIClient,
        builder: BusStopArrivalPreviewBuilder = BusStopArrivalPreviewBuilder(),
        refreshInterval: Duration = .seconds(20),
        freshnessInterval: TimeInterval = 15,
        now: @escaping () -> Date = Date.init,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { duration in
            try await ContinuousClock().sleep(for: duration)
        }
    ) {
        self.apiClient = apiClient
        self.builder = builder
        self.refreshInterval = refreshInterval
        self.freshnessInterval = freshnessInterval
        self.now = now
        self.sleep = sleep
    }

    func state(for stopCode: String) -> BusStopArrivalPreviewState {
        states[stopCode] ?? .idle
    }

    func load(stopCode: String, force: Bool = false) async {
        guard !requestsInFlight.contains(stopCode) else {
            return
        }
        if !force,
           let lastUpdated = lastUpdated[stopCode],
           now().timeIntervalSince(lastUpdated) < freshnessInterval {
            return
        }

        requestsInFlight.insert(stopCode)
        if case .loaded = state(for: stopCode) {
            // Keep the existing preview visible while refreshing.
        } else {
            states[stopCode] = .loading
        }
        defer { requestsInFlight.remove(stopCode) }

        do {
            let response = try await apiClient.arrivals(for: stopCode)
            try Task.checkCancellation()

            let previews = builder.previews(from: response.services)
            states[stopCode] = previews.isEmpty ? .empty : .loaded(previews)
            lastUpdated[stopCode] = now()
        } catch is CancellationError {
            return
        } catch {
            if case .loaded = state(for: stopCode) {
                return
            }
            states[stopCode] = .failed(error.localizedDescription)
        }
    }

    func runAutoRefresh(stopCode: String) async {
        await load(stopCode: stopCode)

        while !Task.isCancelled {
            do {
                try await sleep(refreshInterval)
                try Task.checkCancellation()
            } catch {
                return
            }

            await load(stopCode: stopCode)
        }
    }
}
