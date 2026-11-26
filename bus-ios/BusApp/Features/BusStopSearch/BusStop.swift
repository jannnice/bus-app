import Foundation

struct BusStop: Codable, Hashable, Identifiable, Sendable {
    let stopCode: String
    let roadName: String
    let description: String
    let latitude: Double
    let longitude: Double

    var id: String { stopCode }
}
