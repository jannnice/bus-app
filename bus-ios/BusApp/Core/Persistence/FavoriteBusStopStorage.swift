import Foundation

@MainActor
protocol FavoriteBusStopStorage {
    func load() throws -> [BusStop]
    func save(_ busStops: [BusStop]) throws
}
