import Foundation
import Testing
@testable import PufferCore

@Test func testDiveDateRollsAtNYMidnight() {
    #expect(DiveClock.diveDate(at: date(2026, 11, 16, 22, 59, zone: "America/Chicago")) == "2026-11-16")
    #expect(DiveClock.diveDate(at: date(2026, 11, 16, 23, 0, zone: "America/Chicago")) == "2026-11-17")
}

@Test func testNextResetAcrossDST() {
    #expect(DiveClock.nextReset(after: date(2026, 3, 7, 12, zone: "America/New_York")) == utc("2026-03-08T05:00:00Z"))
    #expect(DiveClock.nextReset(after: date(2026, 10, 31, 12, zone: "America/New_York")) == utc("2026-11-01T04:00:00Z"))
}

@Test func testNextResetIsStrictlyAfterMidnight() {
    let midnight = utc("2026-11-17T05:00:00Z") // 00:00 NY
    #expect(DiveClock.nextReset(after: midnight) == utc("2026-11-18T05:00:00Z"))
}
