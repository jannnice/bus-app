import Foundation

actor WidgetArrivalLoader {
    static let shared = WidgetArrivalLoader(client: makeClient())
    static let automaticInterval: TimeInterval = 15 * 60
    private static let manualCooldown: TimeInterval = 20

    private var inFlight: [String: Task<Void, Never>] = [:]
    private let client: (any BusArrivalAPIClient)?
    private let openData: @Sendable () -> BusWidgetData?
    private let now: @Sendable () -> Date

    init(
        client: (any BusArrivalAPIClient)?,
        openData: @escaping @Sendable () -> BusWidgetData? = BusWidgetData.open,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.client = client
        self.openData = openData
        self.now = now
    }

    private static func makeClient() -> BackendAPIClient? {
        guard let baseURL = AppConfiguration.configuredBackendURL else { return nil }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 7
        return BackendAPIClient(
            baseURL: baseURL,
            apiToken: AppConfiguration.backendAPIToken,
            session: URLSession(configuration: configuration)
        )
    }

    func refresh(stopCode: String, manual: Bool) async {
        if let task = inFlight[stopCode] {
            await task.value
            return
        }

        guard let data = openData(),
              let favorites = try? data.favorites(),
              favorites.contains(where: { $0.stopCode == stopCode }),
              BusWidgetLink.arrivals(stopCode).url != nil else { return }

        let now = now()
        if let attempt = data.attempt(for: stopCode) {
            let elapsed = now.timeIntervalSince(attempt.startedAt)
            let automaticDelay = attempt.failure?.retryDelay ?? Self.automaticInterval
            let manualDelay = attempt.failure == .rateLimited ? 60 : Self.manualCooldown
            if elapsed >= 0, elapsed < (manual ? manualDelay : automaticDelay) { return }
        }
        if !manual, let snapshot = data.snapshot(for: stopCode),
           abs(now.timeIntervalSince(snapshot.fetchedAt)) < Self.manualCooldown { return }

        let task = Task { await fetch(stopCode: stopCode, startedAt: now) }
        inFlight[stopCode] = task
        await task.value
        inFlight[stopCode] = nil
    }

    private func fetch(stopCode: String, startedAt: Date) async {
        guard let data = openData() else { return }
        data.save(BusWidgetRefreshAttempt(startedAt: startedAt, failure: nil), for: stopCode)

        let failure: BusWidgetRefreshFailure?
        if let client {
            do {
                let response = try await client.arrivals(for: stopCode)
                guard response.stopCode == stopCode else { throw BackendAPIError.invalidResponse }
                data.save(
                    BusWidgetSnapshot(response: response, fetchedAt: startedAt),
                    for: stopCode,
                    fromApp: false
                )
                failure = nil
            } catch {
                failure = BusWidgetRefreshFailure(error: error)
            }
        } else {
            failure = .configuration
        }

        data.save(BusWidgetRefreshAttempt(startedAt: startedAt, failure: failure), for: stopCode)
    }
}
