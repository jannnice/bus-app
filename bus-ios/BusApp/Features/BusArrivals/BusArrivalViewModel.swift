import Foundation
import Observation

enum BusArrivalViewState: Equatable {
    case loading
    case loaded
    case empty
    case failed(String)
}

@MainActor
@Observable
final class BusArrivalViewModel {
    private(set) var state: BusArrivalViewState = .loading
    private(set) var services: [BusServiceArrival] = []

    private let stopCode: String
    private let apiClient: any BusArrivalAPIClient
    private let refreshInterval: Duration
    private let sleep: @Sendable (Duration) async throws -> Void
    private var isRequestInFlight = false
    private var autoRefreshGeneration = 0

    init(
        stopCode: String,
        apiClient: any BusArrivalAPIClient,
        refreshInterval: Duration = .seconds(20),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { duration in
            try await ContinuousClock().sleep(for: duration)
        }
    ) {
        self.stopCode = stopCode
        self.apiClient = apiClient
        self.refreshInterval = refreshInterval
        self.sleep = sleep
    }

    func load() async {
        guard !isRequestInFlight else {
            return
        }

        isRequestInFlight = true
        if services.isEmpty {
            state = .loading
        }

        defer { isRequestInFlight = false }

        do {
            let response = try await apiClient.arrivals(for: stopCode)
            try Task.checkCancellation()

            services = response.services
            state = response.services.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            services = []
            state = .failed(error.localizedDescription)
        }
    }

    func runAutoRefresh() async {
        autoRefreshGeneration += 1
        let generation = autoRefreshGeneration

        await load()

        while !Task.isCancelled && generation == autoRefreshGeneration {
            do {
                try await sleep(refreshInterval)
                try Task.checkCancellation()
            } catch {
                return
            }

            guard generation == autoRefreshGeneration else {
                return
            }

            await load()
        }
    }
}
