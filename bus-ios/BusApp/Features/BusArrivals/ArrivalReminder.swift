import Foundation

struct ArrivalReminder: Equatable, Sendable {
    let identifier: String
    let stopCode: String
    let stopName: String
    let serviceNo: String
    let estimatedArrival: Date
    let notificationDate: Date
    let leadTimeMinutes: Int

    static func identifier(stopCode: String, serviceNo: String) -> String {
        "bus-arrival-reminder.\(stopCode).\(serviceNo)"
    }
}

enum ArrivalReminderPlanningError: LocalizedError, Equatable {
    case predictionUnavailable
    case arrivalTooSoon

    var errorDescription: String? {
        switch self {
        case .predictionUnavailable:
            "The next arrival does not have an estimated time."
        case .arrivalTooSoon:
            "That bus is too close to schedule this reminder."
        }
    }
}

struct ArrivalReminderPlanner: Sendable {
    func makeReminder(
        stopCode: String,
        stopName: String,
        service: BusServiceArrival,
        leadTimeMinutes: Int,
        now: Date
    ) throws -> ArrivalReminder {
        guard let estimatedArrival = service.arrivals.first?.estimatedArrival else {
            throw ArrivalReminderPlanningError.predictionUnavailable
        }

        let notificationDate = estimatedArrival.addingTimeInterval(
            -TimeInterval(leadTimeMinutes * 60)
        )
        guard notificationDate > now else {
            throw ArrivalReminderPlanningError.arrivalTooSoon
        }

        return ArrivalReminder(
            identifier: ArrivalReminder.identifier(
                stopCode: stopCode,
                serviceNo: service.serviceNo
            ),
            stopCode: stopCode,
            stopName: stopName,
            serviceNo: service.serviceNo,
            estimatedArrival: estimatedArrival,
            notificationDate: notificationDate,
            leadTimeMinutes: leadTimeMinutes
        )
    }
}
