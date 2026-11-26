import Foundation

struct BusWidgetData {
    static let groupIdentifier = "group.com.jannicesuciptono.BusApp"
    static let favoritesKey = "favoriteBusStops"
    static let widgetKind = "FavoriteStopArrivals"

    let defaults: UserDefaults

    static func open() -> Self? {
        guard FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        ) != nil, let defaults = UserDefaults(suiteName: groupIdentifier) else {
            return nil
        }
        return Self(defaults: defaults)
    }

    func favorites() throws -> [BusStop] {
        guard let data = defaults.data(forKey: Self.favoritesKey) else { return [] }
        return try JSONDecoder().decode([BusStop].self, from: data)
    }

    func snapshot(for stopCode: String) -> BusWidgetSnapshot? {
        let app = appSnapshot(for: stopCode)
        let widget = read(BusWidgetSnapshot.self, key: "widgetSnapshot.v1.\(stopCode)")
        return [app, widget].compactMap { $0 }.max { $0.fetchedAt < $1.fetchedAt }
    }

    func appSnapshot(for stopCode: String) -> BusWidgetSnapshot? {
        read(BusWidgetSnapshot.self, key: "appWidgetSnapshot.v1.\(stopCode)")
    }

    func save(_ snapshot: BusWidgetSnapshot, for stopCode: String, fromApp: Bool) {
        let prefix = fromApp ? "appWidgetSnapshot" : "widgetSnapshot"
        let key = "\(prefix).v1.\(stopCode)"
        if let current = read(BusWidgetSnapshot.self, key: key), current.fetchedAt > snapshot.fetchedAt {
            return
        }
        write(snapshot, key: key)
    }

    func attempt(for stopCode: String) -> BusWidgetRefreshAttempt? {
        read(BusWidgetRefreshAttempt.self, key: "widgetAttempt.v1.\(stopCode)")
    }

    func save(_ attempt: BusWidgetRefreshAttempt, for stopCode: String) {
        write(attempt, key: "widgetAttempt.v1.\(stopCode)")
    }

    private func read<Value: Decodable>(_ type: Value.Type, key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func write(_ value: some Encodable, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}

struct BusWidgetSnapshot: Codable, Equatable, Sendable {
    static let maximumAge: TimeInterval = 5 * 60

    let fetchedAt: Date
    let arrivals: [BusStopArrivalPreview]

    init(response: BusArrivalResponse, fetchedAt: Date) {
        self.fetchedAt = fetchedAt
        arrivals = BusStopArrivalPreviewBuilder().previews(from: response.services, after: fetchedAt)
    }

    func predictions(at date: Date) -> [BusStopArrivalPreview] {
        guard date < fetchedAt.addingTimeInterval(Self.maximumAge) else { return [] }
        return arrivals.filter { $0.estimatedArrival > date }
    }

    func isExpired(at date: Date) -> Bool {
        date >= fetchedAt.addingTimeInterval(Self.maximumAge)
            || (!arrivals.isEmpty && predictions(at: date).isEmpty)
    }
}

struct BusWidgetRefreshAttempt: Codable, Sendable {
    let startedAt: Date
    let failure: BusWidgetRefreshFailure?
}

enum BusWidgetRefreshFailure: String, Codable, Sendable {
    case offline, unavailable, authentication, rateLimited, configuration

    init(error: Error) {
        switch error {
        case BackendAPIError.server(statusCode: 401, message: _),
             BackendAPIError.server(statusCode: 403, message: _):
            self = .authentication
        case BackendAPIError.server(statusCode: 429, message: _):
            self = .rateLimited
        case let error as URLError where error.code == .notConnectedToInternet
            || error.code == .networkConnectionLost:
            self = .offline
        default:
            self = .unavailable
        }
    }

    var retryDelay: TimeInterval {
        switch self {
        case .authentication, .configuration: 60 * 60
        case .offline, .unavailable, .rateLimited: 30 * 60
        }
    }
}
