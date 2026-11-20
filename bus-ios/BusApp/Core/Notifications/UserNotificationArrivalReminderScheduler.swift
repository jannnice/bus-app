import Foundation
@preconcurrency import UserNotifications

struct ArrivalReminderNotificationRequestFactory {
    private enum UserInfoKey {
        static let reminder = "arrivalReminder"
        static let stopCode = "stopCode"
        static let stopName = "stopName"
        static let serviceNo = "serviceNo"
        static let estimatedArrival = "estimatedArrival"
        static let notificationDate = "notificationDate"
        static let leadTimeMinutes = "leadTimeMinutes"
    }

    func request(for reminder: ArrivalReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Bus \(reminder.serviceNo) arriving soon"
        content.body = "Bus \(reminder.serviceNo) is about \(reminder.leadTimeMinutes) "
            + "minutes from \(reminder.stopName)."
        content.sound = .default
        content.userInfo = [
            UserInfoKey.reminder: true,
            UserInfoKey.stopCode: reminder.stopCode,
            UserInfoKey.stopName: reminder.stopName,
            UserInfoKey.serviceNo: reminder.serviceNo,
            UserInfoKey.estimatedArrival: reminder.estimatedArrival.timeIntervalSince1970,
            UserInfoKey.notificationDate: reminder.notificationDate.timeIntervalSince1970,
            UserInfoKey.leadTimeMinutes: reminder.leadTimeMinutes
        ]

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminder.notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        return UNNotificationRequest(
            identifier: reminder.identifier,
            content: content,
            trigger: trigger
        )
    }

    func reminder(from request: UNNotificationRequest) -> ArrivalReminder? {
        let userInfo = request.content.userInfo
        guard userInfo[UserInfoKey.reminder] as? Bool == true,
              let stopCode = userInfo[UserInfoKey.stopCode] as? String,
              let stopName = userInfo[UserInfoKey.stopName] as? String,
              let serviceNo = userInfo[UserInfoKey.serviceNo] as? String,
              let estimatedArrival = userInfo[UserInfoKey.estimatedArrival] as? Double,
              let notificationDate = userInfo[UserInfoKey.notificationDate] as? Double,
              let leadTimeMinutes = userInfo[UserInfoKey.leadTimeMinutes] as? Int else {
            return nil
        }

        return ArrivalReminder(
            identifier: request.identifier,
            stopCode: stopCode,
            stopName: stopName,
            serviceNo: serviceNo,
            estimatedArrival: Date(timeIntervalSince1970: estimatedArrival),
            notificationDate: Date(timeIntervalSince1970: notificationDate),
            leadTimeMinutes: leadTimeMinutes
        )
    }
}

@MainActor
struct UserNotificationArrivalReminderScheduler: ArrivalReminderScheduling {
    private let notificationCenter: UNUserNotificationCenter
    private let requestFactory: ArrivalReminderNotificationRequestFactory

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        requestFactory: ArrivalReminderNotificationRequestFactory = .init()
    ) {
        self.notificationCenter = notificationCenter
        self.requestFactory = requestFactory
    }

    func authorizationStatus() async -> ArrivalReminderAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound])
    }

    func pendingReminders() async -> [ArrivalReminder] {
        await notificationCenter.pendingNotificationRequests()
            .compactMap(requestFactory.reminder)
    }

    func schedule(_ reminder: ArrivalReminder) async throws {
        try await notificationCenter.add(requestFactory.request(for: reminder))
    }

    func cancel(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
