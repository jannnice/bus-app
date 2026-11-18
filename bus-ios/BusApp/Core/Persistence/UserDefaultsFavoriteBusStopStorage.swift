import Foundation

@MainActor
struct UserDefaultsFavoriteBusStopStorage: FavoriteBusStopStorage {
    private let userDefaults: UserDefaults
    private let storageKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "favoriteBusStops"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        encoder = JSONEncoder()
        decoder = JSONDecoder()
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
    }
}
