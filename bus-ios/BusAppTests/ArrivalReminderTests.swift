import Foundation
import UserNotifications
import XCTest
@testable import BusApp

final class ArrivalReminderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testPlannerTargetsTheNextDisplayedBus() throws {
        let service = makeService(estimatedArrival: now.addingTimeInterval(600))

        let reminder = try ArrivalReminderPlanner().makeReminder(
            stopCode: "83139",
            stopName: "Opp Roxy Sq",
            service: service,
            leadTimeMinutes: 3,
            now: now
        )

        XCTAssertEqual(reminder.identifier, "bus-arrival-reminder.83139.15")
        XCTAssertEqual(reminder.serviceNo, "15")
        XCTAssertEqual(reminder.estimatedArrival, now.addingTimeInterval(600))
        XCTAssertEqual(reminder.notificationDate, now.addingTimeInterval(420))
        XCTAssertEqual(reminder.leadTimeMinutes, 3)
    }

    func testPlannerRejectsUnavailableAndTooSoonPredictions() {
        XCTAssertThrowsError(
            try ArrivalReminderPlanner().makeReminder(
                stopCode: "83139",
                stopName: "Opp Roxy Sq",
                service: makeService(estimatedArrival: nil),
                leadTimeMinutes: 3,
                now: now
            )
        ) { error in
            XCTAssertEqual(error as? ArrivalReminderPlanningError, .predictionUnavailable)
        }

        XCTAssertThrowsError(
            try ArrivalReminderPlanner().makeReminder(
                stopCode: "83139",
                stopName: "Opp Roxy Sq",
                service: makeService(estimatedArrival: now.addingTimeInterval(120)),
                leadTimeMinutes: 3,
                now: now
            )
        ) { error in
            XCTAssertEqual(error as? ArrivalReminderPlanningError, .arrivalTooSoon)
        }
    }

    func testNotificationRequestIsOneOffAndRoundTripsReminderDetails() {
        let reminder = ArrivalReminder(
            identifier: "bus-arrival-reminder.83139.15",
            stopCode: "83139",
            stopName: "Opp Roxy Sq",
            serviceNo: "15",
            estimatedArrival: now.addingTimeInterval(600),
            notificationDate: now.addingTimeInterval(420),
            leadTimeMinutes: 3
        )
        let factory = ArrivalReminderNotificationRequestFactory()

        let request = factory.request(for: reminder)

        let trigger = request.trigger as? UNCalendarNotificationTrigger
        XCTAssertNotNil(trigger)
        XCTAssertEqual(trigger?.repeats, false)
        XCTAssertEqual(request.identifier, reminder.identifier)
        XCTAssertEqual(request.content.title, "Bus 15 arriving soon")
        XCTAssertEqual(factory.reminder(from: request), reminder)
    }

    private func makeService(estimatedArrival: Date?) -> BusServiceArrival {
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
