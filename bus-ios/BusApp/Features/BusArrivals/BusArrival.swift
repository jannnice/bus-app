import Foundation

struct BusArrivalResponse: Decodable, Equatable, Sendable {
    let stopCode: String
    let services: [BusServiceArrival]
}

struct BusServiceArrival: Decodable, Equatable, Identifiable, Sendable {
    let serviceNo: String
    let `operator`: String
    let arrivals: [BusArrivalPrediction]

    var id: String { serviceNo }
}

struct BusArrivalPrediction: Decodable, Equatable, Sendable {
    let originCode: String
    let destinationCode: String
    let estimatedArrival: Date?
    let monitored: Bool
    let latitude: Double?
    let longitude: Double?
    let visitNumber: Int?
    let load: BusLoad
    let wheelchairAccessible: Bool
    let type: BusType
}

enum BusLoad: String, Decodable, Equatable, Sendable {
    case seatsAvailable = "SEATS_AVAILABLE"
    case standingAvailable = "STANDING_AVAILABLE"
    case limitedStanding = "LIMITED_STANDING"
    case unknown = "UNKNOWN"

    var displayName: String {
        switch self {
        case .seatsAvailable:
            "Seats available"
        case .standingAvailable:
            "Standing available"
        case .limitedStanding:
            "Limited standing"
        case .unknown:
            "Load unknown"
        }
    }
}

enum BusType: String, Decodable, Equatable, Sendable {
    case singleDeck = "SINGLE_DECK"
    case doubleDeck = "DOUBLE_DECK"
    case bendy = "BENDY"
    case unknown = "UNKNOWN"

    var displayName: String {
        switch self {
        case .singleDeck:
            "Single deck"
        case .doubleDeck:
            "Double deck"
        case .bendy:
            "Bendy"
        case .unknown:
            "Type unknown"
        }
    }
}
