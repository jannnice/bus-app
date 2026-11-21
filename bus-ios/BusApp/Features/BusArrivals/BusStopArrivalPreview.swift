import Foundation

struct BusStopArrivalPreview: Equatable, Identifiable, Sendable {
    let serviceNo: String
    let estimatedArrival: Date

    var id: String { serviceNo }
}

struct BusStopArrivalPreviewBuilder: Sendable {
    func previews(
        from services: [BusServiceArrival],
        limit: Int = 4
    ) -> [BusStopArrivalPreview] {
        services.compactMap { service in
            guard let nextArrival = service.arrivals.compactMap(\.estimatedArrival).min() else {
                return nil
            }
            return BusStopArrivalPreview(
                serviceNo: service.serviceNo,
                estimatedArrival: nextArrival
            )
        }
        .sorted { first, second in
            if first.estimatedArrival == second.estimatedArrival {
                return first.serviceNo.localizedStandardCompare(second.serviceNo) == .orderedAscending
            }
            return first.estimatedArrival < second.estimatedArrival
        }
        .prefix(max(0, limit))
        .map { $0 }
    }
}
