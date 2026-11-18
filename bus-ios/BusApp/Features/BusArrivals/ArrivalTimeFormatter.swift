import Foundation

struct ArrivalTimeFormatter: Sendable {
    func string(for estimatedArrival: Date?, relativeTo now: Date) -> String {
        guard let estimatedArrival else {
            return "—"
        }

        let wholeMinutes = Int(estimatedArrival.timeIntervalSince(now) / 60)
        guard wholeMinutes > 0 else {
            return "Arr"
        }

        return "\(wholeMinutes) min"
    }
}
