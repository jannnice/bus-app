import Foundation

enum ArrivalReminderAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
}

@MainActor
protocol ArrivalReminderScheduling {
    func authorizationStatus() async -> ArrivalReminderAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func pendingReminders() async -> [ArrivalReminder]
    func schedule(_ reminder: ArrivalReminder) async throws
    func cancel(identifier: String)
}
