import Foundation
import Testing
@testable import PufferCore

private let planner = ReminderPlanner(reminderHour: 19, localZone: chicago)
private func at(_ h: Int, _ m: Int = 0) -> Date { date(2026, 11, 16, h, m, zone: "America/Chicago") }
private let today = "2026-11-16"
private func status(_ done: Bool?, on day: String = today) -> DiveStatus {
    DiveStatus(diveDate: day, diveDone: done, updatedAt: "2026-11-16T12:00:00-06:00")
}

@Test func testNothingBeforeSeven() {
    #expect(planner.due(now: at(18, 59), status: status(false), alreadySent: []) == nil)
}

@Test func testMainAtSeven() {
    #expect(planner.due(now: at(19), status: status(false), alreadySent: []) == .main)
}

@Test func testWakeAfterMissedMainFiresOnce() {
    #expect(planner.due(now: at(20, 30), status: status(false), alreadySent: []) == .main)
    #expect(planner.due(now: at(20, 30), status: status(false), alreadySent: [.main]) == nil)
    #expect(planner.due(now: at(21, 59), status: status(false), alreadySent: [.main]) == nil)
    #expect(planner.due(now: at(22), status: status(false), alreadySent: [.main]) == .last)
}

@Test func testWakeAfterBothTimesFiresOnlyLast() {
    #expect(planner.due(now: at(22, 30), status: status(false), alreadySent: []) == .last)
    #expect(planner.due(now: at(22, 30), status: status(false), alreadySent: [.last]) == nil)
}

@Test func testNothingAfterReset() {
    // 23:10 CST is already the next NY day; nothing sent yet for it, but it's before 19:00 local of that day.
    #expect(planner.due(now: at(23, 10), status: status(false), alreadySent: []) == nil)
}

@Test func testNothingWhenDone() {
    #expect(planner.due(now: at(20), status: status(true), alreadySent: []) == nil)
    #expect(planner.due(now: at(22, 30), status: status(true), alreadySent: []) == nil)
}

@Test func testUnknownStillReminds() {
    #expect(planner.due(now: at(19, 5), status: status(nil), alreadySent: []) == .main)
    #expect(planner.due(now: at(19, 5), status: nil, alreadySent: []) == .main)
}

@Test func testDoneYesterdayIsNotDoneToday() {
    #expect(planner.due(now: at(19, 5), status: status(true, on: "2026-11-15"), alreadySent: []) == .main)
}

@Test func testOffDisablesMainOnly() {
    let off = ReminderPlanner(reminderHour: nil, localZone: chicago)
    #expect(off.due(now: at(20), status: status(false), alreadySent: []) == nil)
    #expect(off.due(now: at(22, 1), status: status(false), alreadySent: []) == .last)
}

@Test func testNextFireIsSevenThenTen() {
    #expect(planner.nextFire(after: at(12), status: status(false), alreadySent: []) == at(19))
    #expect(planner.nextFire(after: at(19, 1), status: status(false), alreadySent: [.main]) == at(22))
    #expect(planner.nextFire(after: at(22, 1), status: status(false), alreadySent: [.main, .last]) == nil)
    #expect(planner.nextFire(after: at(12), status: status(true), alreadySent: []) == nil)
}

// Any hour of the day can be picked.

@Test func testMorningReminder() {
    let p = ReminderPlanner(reminderHour: 8, localZone: chicago)
    #expect(p.due(now: at(7, 59), status: status(false), alreadySent: []) == nil)
    #expect(p.due(now: at(8), status: status(false), alreadySent: []) == .main)
}

@Test func testMidnightReminder() {
    let p = ReminderPlanner(reminderHour: 0, localZone: chicago)
    #expect(p.due(now: at(0, 30), status: status(false), alreadySent: []) == .main)
}

@Test func testTenPmReminderSendsOneMessage() {
    let p = ReminderPlanner(reminderHour: 22, localZone: chicago)
    #expect(p.due(now: at(22), status: status(false), alreadySent: []) == .last)
    #expect(p.due(now: at(22, 5), status: status(false), alreadySent: [.last]) == nil)
}

@Test func testElevenPmReminderIsForTheNewDiveDay() {
    // 23:00 Chicago is midnight in New York: the new dive is out.
    let p = ReminderPlanner(reminderHour: 23, localZone: chicago)
    #expect(p.due(now: at(22, 30), status: status(false), alreadySent: []) == .last)
    #expect(p.due(now: at(23), status: status(false, on: "2026-11-17"), alreadySent: []) == .main)
    #expect(p.due(now: at(23), status: status(true, on: "2026-11-17"), alreadySent: []) == nil)
}

@Test func testHourLabels() {
    #expect(ReminderHours.all == Array(0...23))
    #expect(ReminderHours.label(0) == "12am")
    #expect(ReminderHours.label(9) == "9am")
    #expect(ReminderHours.label(12) == "12pm")
    #expect(ReminderHours.label(19) == "7pm")
    #expect(ReminderHours.label(23) == "11pm")
}
