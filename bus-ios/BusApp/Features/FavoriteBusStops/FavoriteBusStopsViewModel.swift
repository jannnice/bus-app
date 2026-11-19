import Foundation
import Observation

enum FavoriteBusStopsViewState: Equatable {
    case empty
    case loaded
    case failed(String)
}

@MainActor
@Observable
final class FavoriteBusStopsViewModel {
    private(set) var busStops: [BusStop] = []
    private(set) var state: FavoriteBusStopsViewState = .empty

    private let storage: any FavoriteBusStopStorage

    init(storage: any FavoriteBusStopStorage) {
        self.storage = storage
        reload()
    }

    func isFavorite(_ busStop: BusStop) -> Bool {
        busStops.contains { $0.stopCode == busStop.stopCode }
    }

    func toggle(_ busStop: BusStop) {
        performMutation { busStops in
            if let index = busStops.firstIndex(where: { $0.stopCode == busStop.stopCode }) {
                busStops.remove(at: index)
            } else {
                busStops.append(busStop)
            }
        }
    }

    func remove(atOffsets offsets: IndexSet) {
        performMutation { busStops in
            for index in offsets.sorted(by: >) {
                busStops.remove(at: index)
            }
        }
    }

    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        performMutation { busStops in
            let movingStops = offsets.sorted().map { busStops[$0] }

            for index in offsets.sorted(by: >) {
                busStops.remove(at: index)
            }

            let removedBeforeDestination = offsets.filter { $0 < destination }.count
            let adjustedDestination = destination - removedBeforeDestination
            let safeDestination = min(max(0, adjustedDestination), busStops.count)
            busStops.insert(contentsOf: movingStops, at: safeDestination)
        }
    }

    func reload() {
        do {
            busStops = Self.removingDuplicates(from: try storage.load())
            updateState()
        } catch {
            busStops = []
            state = .failed(error.localizedDescription)
        }
    }

    func dismissError() {
        updateState()
    }

    private func performMutation(_ mutation: (inout [BusStop]) -> Void) {
        let previousBusStops = busStops
        mutation(&busStops)

        do {
            try storage.save(busStops)
            updateState()
        } catch {
            busStops = previousBusStops
            state = .failed(error.localizedDescription)
        }
    }

    private func updateState() {
        state = busStops.isEmpty ? .empty : .loaded
    }

    private static func removingDuplicates(from busStops: [BusStop]) -> [BusStop] {
        var seenStopCodes: Set<String> = []
        return busStops.filter { seenStopCodes.insert($0.stopCode).inserted }
    }
}

extension FavoriteBusStopsViewModel {
    static func preview(busStops: [BusStop] = []) -> FavoriteBusStopsViewModel {
        FavoriteBusStopsViewModel(
            storage: PreviewFavoriteBusStopStorage(busStops: busStops)
        )
    }
}

@MainActor
private final class PreviewFavoriteBusStopStorage: FavoriteBusStopStorage {
    private var busStops: [BusStop]

    init(busStops: [BusStop]) {
        self.busStops = busStops
    }

    func load() throws -> [BusStop] {
        busStops
    }

    func save(_ busStops: [BusStop]) throws {
        self.busStops = busStops
    }
}
