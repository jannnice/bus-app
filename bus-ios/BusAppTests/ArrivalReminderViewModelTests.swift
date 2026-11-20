import Foundation
import XCTest
@testable import BusApp

@MainActor
final class ArrivalReminderViewModelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testSchedulingRequestsPermissionAndPublishesOneActiveReminder() async {
        let scheduler = ArrivalReminderSchedulerStub(
            authorizationStatus: .notDetermined,
            requestAuthorizationResult: true
        )
        let viewModel = makeViewModel(scheduler: scheduler)

        await viewModel.scheduleReminder(
            for: makeService(estimatedArrival: now.addingTimeInterval(600)),
            leadTimeMinutes: 3
        )

        XCTAssertEqual(scheduler.requestAuthorizationCount, 1)
        XCTAssertEqual(scheduler.scheduledReminders.count, 1)
        XCTAssertEqual(scheduler.scheduledReminders.first?.leadTimeMinutes, 3)
        XCTAssertNotNil(viewModel.activeReminder(for: "15"))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testReschedulingSameServiceReusesIdentifierAndReplacesActiveReminder() async {
        let scheduler = ArrivalReminderSchedulerStub(authorizationStatus: .authorized)
        let viewModel = makeViewModel(scheduler: scheduler)
        let service = makeService(estimatedArrival: now.addingTimeInterval(900))

        await viewModel.scheduleReminder(for: service, leadTimeMinutes: 10)
        await viewModel.scheduleReminder(for: service, leadTimeMinutes: 5)

        XCTAssertEqual(scheduler.scheduledReminders.count, 2)
        XCTAssertEqual(
            scheduler.scheduledReminders.map(\.identifier),
            ["bus-arrival-reminder.83139.15", "bus-arrival-reminder.83139.15"]
        )
        XCTAssertEqual(viewModel.activeReminder(for: "15")?.leadTimeMinutes, 5)
        XCTAssertEqual(viewModel.activeReminders.count, 1)
    }

    func testDeniedPermissionPublishesSettingsErrorWithoutScheduling() async {
        let scheduler = ArrivalReminderSchedulerStub(authorizationStatus: .denied)
        let viewModel = makeViewModel(scheduler: scheduler)

        await viewModel.scheduleReminder(
            for: makeService(estimatedArrival: now.addingTimeInterval(600)),
            leadTimeMinutes: 3
        )

        XCTAssertTrue(scheduler.scheduledReminders.isEmpty)
        XCTAssertTrue(viewModel.permissionDenied)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Allow notifications in Settings to create arrival reminders."
        )
    }

    func testSchedulingFailurePublishesError() async {
        let scheduler = ArrivalReminderSchedulerStub(authorizationStatus: .authorized)
        scheduler.scheduleError = ArrivalReminderTestError.couldNotSchedule
        let viewModel = makeViewModel(scheduler: scheduler)

        await viewModel.scheduleReminder(
            for: makeService(estimatedArrival: now.addingTimeInterval(600)),
            leadTimeMinutes: 3
        )

        XCTAssertNil(viewModel.activeReminder(for: "15"))
        XCTAssertEqual(viewModel.errorMessage, "The reminder could not be scheduled.")
    }

    func testCancelRemovesOnlyTheSelectedOneOffReminder() async {
        let scheduler = ArrivalReminderSchedulerStub(authorizationStatus: .authorized)
        let viewModel = makeViewModel(scheduler: scheduler)
        await viewModel.scheduleReminder(
            for: makeService(estimatedArrival: now.addingTimeInterval(600)),
            leadTimeMinutes: 3
        )

        viewModel.cancelReminder(for: "15")

        XCTAssertEqual(scheduler.cancelledIdentifiers, ["bus-arrival-reminder.83139.15"])
        XCTAssertNil(viewModel.activeReminder(for: "15"))
    }

    func testLoadingPendingRemindersFiltersOtherStopsAndExpiredNotifications() async {
        let validReminder = makeReminder(
            identifier: "bus-arrival-reminder.83139.15",
            stopCode: "83139",
            notificationDate: now.addingTimeInterval(300)
        )
        let otherStopReminder = makeReminder(
            identifier: "bus-arrival-reminder.01012.15",
            stopCode: "01012",
            notificationDate: now.addingTimeInterval(300)
        )
        let expiredReminder = makeReminder(
            identifier: "bus-arrival-reminder.83139.16",
            stopCode: "83139",
            notificationDate: now.addingTimeInterval(-1)
        )
        let scheduler = ArrivalReminderSchedulerStub(
            authorizationStatus: .authorized,
            pendingReminders: [validReminder, otherStopReminder, expiredReminder]
        )
        let viewModel = makeViewModel(scheduler: scheduler)

        await viewModel.loadPendingReminders()

        XCTAssertEqual(viewModel.activeReminders, [validReminder.identifier: validReminder])
    }

    func testAvailableLeadTimesExcludeTimesThatHaveAlreadyPassed() {
        let scheduler = ArrivalReminderSchedulerStub(authorizationStatus: .authorized)
        let viewModel = makeViewModel(scheduler: scheduler)

        let leadTimes = viewModel.availableLeadTimes(
            for: makeService(estimatedArrival: now.addingTimeInterval(250))
        )

        XCTAssertEqual(leadTimes, [1, 3])
    }

    private func makeViewModel(
        scheduler: ArrivalReminderSchedulerStub
    ) -> ArrivalReminderViewModel {
        ArrivalReminderViewModel(
            stopCode: "83139",
            stopName: "Opp Roxy Sq",
            scheduler: scheduler,
            now: { self.now }
        )
    }

    private func makeReminder(
        identifier: String,
        stopCode: String,
        notificationDate: Date
    ) -> ArrivalReminder {
        ArrivalReminder(
            identifier: identifier,
            stopCode: stopCode,
            stopName: "Test Stop",
            serviceNo: "15",
            estimatedArrival: now.addingTimeInterval(600),
            notificationDate: notificationDate,
            leadTimeMinutes: 3
        )
    }

    private func makeService(estimatedArrival: Date) -> BusServiceArrival {
        BusServiceArrival(
            serviceNo: "15",
            operator: "GAS",
            arrivals: [
                BusArrivalPrediction(
                    originCode: "77009",
                    destinationCode: "77009",
                    estimatedArrival: estimatedArrival,
                    monitored: true,
                    latitude: 1.315,
                    longitude: 103.905,
                    visitNumber: 1,
                    load: .seatsAvailable,
                    wheelchairAccessible: true,
                    type: .singleDeck
                )
            ]
        )
    }
}

@MainActor
private final class ArrivalReminderSchedulerStub: ArrivalReminderScheduling {
    var authorizationStatusValue: ArrivalReminderAuthorizationStatus
    var requestAuthorizationResult: Bool
    var pendingReminderValues: [ArrivalReminder]
    var scheduleError: Error?
    private(set) var requestAuthorizationCount = 0
    private(set) var scheduledReminders: [ArrivalReminder] = []
    private(set) var cancelledIdentifiers: [String] = []

    init(
        authorizationStatus: ArrivalReminderAuthorizationStatus,
        requestAuthorizationResult: Bool = false,
        pendingReminders: [ArrivalReminder] = []
    ) {
        authorizationStatusValue = authorizationStatus
        self.requestAuthorizationResult = requestAuthorizationResult
        pendingReminderValues = pendingReminders
    }

    func authorizationStatus() async -> ArrivalReminderAuthorizationStatus {
        authorizationStatusValue
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCount += 1
        return requestAuthorizationResult
    }

    func pendingReminders() async -> [ArrivalReminder] {
        pendingReminderValues
    }

    func schedule(_ reminder: ArrivalReminder) async throws {
        if let scheduleError {
            throw scheduleError
        }
        scheduledReminders.append(reminder)
    }

    func cancel(identifier: String) {
        cancelledIdentifiers.append(identifier)
    }
}

private enum ArrivalReminderTestError: LocalizedError {
    case couldNotSchedule

    var errorDescription: String? {
        "The reminder could not be scheduled."
    }
}
