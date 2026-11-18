import Foundation

struct DistanceFormatter: Sendable {
    func string(for distanceMeters: Int) -> String {
        guard distanceMeters >= 1_000 else {
            return "\(distanceMeters) m"
        }

        let distanceKilometers = Double(distanceMeters) / 1_000
        return String(format: "%.1f km", distanceKilometers)
    }
}
