import Foundation
import Observation

@MainActor
@Observable
final class ArrivalReminderViewModel {
    private(set) var activeReminders: [String: ArrivalReminder] = [:]
    private(set) var schedulingServiceNo: String?
    private(set) var errorMessage: String?
    private(set) var permissionDenied = false

    let leadTimeOptions = [1, 3, 5, 10]

    private let stopCode: String
    private let stopName: String
    private let scheduler: any ArrivalReminderScheduling
    private let planner: ArrivalReminderPlanner
    private let now: () -> Date

    init(
        stopCode: String,
        stopName: String,
        scheduler: any ArrivalReminderScheduling,
        planner: ArrivalReminderPlanner = ArrivalReminderPlanner(),
        now: @escaping () -> Date = Date.init
    ) {
        self.stopCode = stopCode
        self.stopName = stopName
        self.scheduler = scheduler
        self.planner = planner
        self.now = now
    }

    func loadPendingReminders() async {
        let currentDate = now()
        activeReminders = Dictionary(
            uniqueKeysWithValues: await scheduler.pendingReminders()
                .filter { $0.stopCode == stopCode && $0.notificationDate > currentDate }
                .map { ($0.identifier, $0) }
        )
    }

    func availableLeadTimes(for service: BusServiceArrival) -> [Int] {
        guard let estimatedArrival = service.arrivals.first?.estimatedArrival else {
            return []
        }

        let currentDate = now()
        return leadTimeOptions.filter { leadTimeMinutes in
            estimatedArrival.addingTimeInterval(-TimeInterval(leadTimeMinutes * 60))
                > currentDate
        }
    }

    func activeReminder(for serviceNo: String) -> ArrivalReminder? {
        let identifier = ArrivalReminder.identifier(
            stopCode: stopCode,
            serviceNo: serviceNo
        )
        guard let reminder = activeReminders[identifier],
              reminder.notificationDate > now() else {
            return nil
        }
        return reminder
    }

    func scheduleReminder(
        for service: BusServiceArrival,
        leadTimeMinutes: Int
    ) async {
        schedulingServiceNo = service.serviceNo
        errorMessage = nil
        permissionDenied = false
        defer { schedulingServiceNo = nil }

        do {
            let reminder = try planner.makeReminder(
                stopCode: stopCode,
                stopName: stopName,
                service: service,
                leadTimeMinutes: leadTimeMinutes,
                now: now()
            )
            guard try await canScheduleNotifications() else {
                permissionDenied = true
                errorMessage = "Allow notifications in Settings to create arrival reminders."
                return
            }

            try await scheduler.schedule(reminder)
            activeReminders[reminder.identifier] = reminder
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelReminder(for serviceNo: String) {
        let identifier = ArrivalReminder.identifier(
            stopCode: stopCode,
            serviceNo: serviceNo
        )
        scheduler.cancel(identifier: identifier)
        activeReminders.removeValue(forKey: identifier)
    }

    func dismissError() {
        errorMessage = nil
        permissionDenied = false
    }

    private func canScheduleNotifications() async throws -> Bool {
        switch await scheduler.authorizationStatus() {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await scheduler.requestAuthorization()
        }
    }
}
