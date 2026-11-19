import Foundation
import XCTest
@testable import BusApp

@MainActor
final class FavoriteBusStopsViewModelTests: XCTestCase {
    func testLoadRestoresFavoritesAndRemovesDuplicateStopCodes() {
        let firstStop = makeBusStop(code: "01012", description: "Hotel Grand Pacific")
        let duplicateStop = makeBusStop(code: "01012", description: "Duplicate")
        let secondStop = makeBusStop(code: "83139", description: "Opp Roxy Sq")
        let storage = FavoriteBusStopStorageStub(
            loadResult: .success([firstStop, duplicateStop, secondStop])
        )

        let viewModel = FavoriteBusStopsViewModel(storage: storage)

        XCTAssertEqual(viewModel.busStops, [firstStop, secondStop])
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testToggleAddsThenRemovesFavoriteAndPersistsBothChanges() {
        let busStop = makeBusStop(code: "01012", description: "Hotel Grand Pacific")
        let storage = FavoriteBusStopStorageStub(loadResult: .success([]))
        let viewModel = FavoriteBusStopsViewModel(storage: storage)

        viewModel.toggle(busStop)

        XCTAssertTrue(viewModel.isFavorite(busStop))
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(storage.savedValues.last, [busStop])

        viewModel.toggle(busStop)

        XCTAssertFalse(viewModel.isFavorite(busStop))
        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertEqual(storage.savedValues.last, [])
    }

    func testDeleteAndMovePersistTheNewOrder() {
        let firstStop = makeBusStop(code: "01012", description: "First")
        let secondStop = makeBusStop(code: "83139", description: "Second")
        let thirdStop = makeBusStop(code: "92049", description: "Third")
        let storage = FavoriteBusStopStorageStub(
            loadResult: .success([firstStop, secondStop, thirdStop])
        )
        let viewModel = FavoriteBusStopsViewModel(storage: storage)

        viewModel.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        XCTAssertEqual(viewModel.busStops, [secondStop, thirdStop, firstStop])
        XCTAssertEqual(storage.savedValues.last, [secondStop, thirdStop, firstStop])

        viewModel.remove(atOffsets: IndexSet(integer: 1))

        XCTAssertEqual(viewModel.busStops, [secondStop, firstStop])
        XCTAssertEqual(storage.savedValues.last, [secondStop, firstStop])
    }

    func testFailedSaveRollsBackMutationAndPublishesError() {
        let busStop = makeBusStop(code: "01012", description: "Hotel Grand Pacific")
        let storage = FavoriteBusStopStorageStub(loadResult: .success([]))
        storage.saveError = FavoriteStorageTestError.couldNotSave
        let viewModel = FavoriteBusStopsViewModel(storage: storage)

        viewModel.toggle(busStop)

        XCTAssertTrue(viewModel.busStops.isEmpty)
        XCTAssertEqual(viewModel.state, .failed("The favourites could not be saved."))

        viewModel.dismissError()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testFailedLoadPublishesErrorAndReloadCanRecover() {
        let busStop = makeBusStop(code: "01012", description: "Hotel Grand Pacific")
        let storage = FavoriteBusStopStorageStub(
            loadResult: .failure(FavoriteStorageTestError.couldNotLoad)
        )
        let viewModel = FavoriteBusStopsViewModel(storage: storage)

        XCTAssertEqual(viewModel.state, .failed("The favourites could not be loaded."))

        storage.loadResult = .success([busStop])
        viewModel.reload()

        XCTAssertEqual(viewModel.busStops, [busStop])
        XCTAssertEqual(viewModel.state, .loaded)
    }

    private func makeBusStop(code: String, description: String) -> BusStop {
        BusStop(
            stopCode: code,
            roadName: "Victoria St",
            description: description,
            latitude: 1.29685,
            longitude: 103.853
        )
    }
}

@MainActor
final class UserDefaultsFavoriteBusStopStorageTests: XCTestCase {
    func testSavedFavoritesCanBeLoadedByANewStorageInstance() throws {
        let suiteName = "FavoriteBusStopStorageTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let busStop = BusStop(
            stopCode: "01012",
            roadName: "Victoria St",
            description: "Hotel Grand Pacific",
            latitude: 1.29685,
            longitude: 103.853
        )

        try UserDefaultsFavoriteBusStopStorage(
            userDefaults: userDefaults
        ).save([busStop])

        let reloadedBusStops = try UserDefaultsFavoriteBusStopStorage(
            userDefaults: userDefaults
        ).load()

        XCTAssertEqual(reloadedBusStops, [busStop])
    }
}

@MainActor
private final class FavoriteBusStopStorageStub: FavoriteBusStopStorage {
    var loadResult: Result<[BusStop], Error>
    var saveError: Error?
    private(set) var savedValues: [[BusStop]] = []

    init(loadResult: Result<[BusStop], Error>) {
        self.loadResult = loadResult
    }

    func load() throws -> [BusStop] {
        try loadResult.get()
    }

    func save(_ busStops: [BusStop]) throws {
        if let saveError {
            throw saveError
        }
        savedValues.append(busStops)
    }
}

private enum FavoriteStorageTestError: LocalizedError {
    case couldNotLoad
    case couldNotSave

    var errorDescription: String? {
        switch self {
        case .couldNotLoad:
            "The favourites could not be loaded."
        case .couldNotSave:
            "The favourites could not be saved."
        }
    }
}
