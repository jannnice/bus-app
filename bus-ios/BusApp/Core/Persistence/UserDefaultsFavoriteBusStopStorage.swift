import Foundation

@MainActor
struct UserDefaultsFavoriteBusStopStorage: FavoriteBusStopStorage {
    private let userDefaults: UserDefaults
    private let storageKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let onSave: () -> Void

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = BusWidgetData.favoritesKey,
        onSave: @escaping () -> Void = {}
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        self.onSave = onSave
    }

    static func migrateFavorites(from legacy: UserDefaults, to shared: UserDefaults) {
        let key = BusWidgetData.favoritesKey
        // An encoded empty array is an intentional value and must win over legacy data.
        guard shared.object(forKey: key) == nil, let data = legacy.data(forKey: key) else { return }
        shared.set(data, forKey: key)
    }

    func load() throws -> [BusStop] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        return try decoder.decode([BusStop].self, from: data)
    }

    func save(_ busStops: [BusStop]) throws {
        let data = try encoder.encode(busStops)
        userDefaults.set(data, forKey: storageKey)
        onSave()
    }
}
