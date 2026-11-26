import AppIntents
import Foundation

struct FavoriteStopEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Bus Stop"
    static let defaultQuery = FavoriteStopQuery()

    let id: String
    let name: String
    let road: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(id) · \(road)")
    }

    init(stop: BusStop) {
        id = stop.stopCode
        name = stop.description
        road = stop.roadName
    }
}

struct FavoriteStopQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FavoriteStopEntity] {
        let favorites = try await suggestedEntities()
        return identifiers.compactMap { id in favorites.first { $0.id == id } }
    }

    func suggestedEntities() async throws -> [FavoriteStopEntity] {
        let stops = try BusWidgetData.open()?.favorites() ?? []
        var seen: Set<String> = []
        return stops.filter { seen.insert($0.stopCode).inserted }.map(FavoriteStopEntity.init)
    }
}

struct FavoriteStopWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Favourite Bus Stop"
    static let description = IntentDescription("Choose a favourite stop to see its next arrivals.")

    @Parameter(title: "Favourite Stop")
    var stop: FavoriteStopEntity?
}

struct RefreshWidgetArrivalsIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Arrivals"
    static let isDiscoverable = false

    @Parameter(title: "Stop Code")
    var stopCode: String

    init() {}

    init(stopCode: String) {
        self.stopCode = stopCode
    }

    func perform() async throws -> some IntentResult {
        await WidgetArrivalLoader.shared.refresh(stopCode: stopCode, manual: true)
        return .result()
    }
}
