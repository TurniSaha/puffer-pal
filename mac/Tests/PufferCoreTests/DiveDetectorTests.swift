import Foundation
import Testing
@testable import PufferCore

private func fixture(_ name: String) -> String {
    let url = Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: "json")!
    return try! String(contentsOf: url, encoding: .utf8)
}

private let today = "2026-11-16"

@Test func testFinishedDailyIsDone() {
    let storage = ["krillion:stats:v1": fixture("stats-daily-done")]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: today) == .done(depthMeters: 4320, streak: 6))
}

@Test func testOtherDateIsNotDone() {
    let storage = ["krillion:stats:v1": fixture("stats-daily-done")]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: "2026-11-17") == .notDone)
}

@Test func testArchiveGameDoesNotCountAsDaily() {
    // Archive games live under krillion-archive-done, never in the daily stats history.
    let storage = ["krillion-archive-done": fixture("archive-done")]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: today) == .notDone)
}

@Test func testEmptyStorageIsNotDone() {
    #expect(DiveDetector.evaluate(storage: [:], diveDate: today) == .notDone)
}

@Test func testUnrecognisedShapeIsUnknown() {
    #expect(DiveDetector.evaluate(storage: ["krillion:stats:v1": "{\"hist\":[]}"], diveDate: today) == .unknown)
    #expect(DiveDetector.evaluate(storage: ["krillion:stats:v1": "not json"], diveDate: today) == .unknown)
    let badEntry = "{\"history\":{\"2026-11-16\":{\"points\":4}}}"
    #expect(DiveDetector.evaluate(storage: ["krillion:stats:v1": badEntry], diveDate: today) == .unknown)
}

@Test func testFinishedGameStateCountsBeforeStatsLand() {
    let storage = ["krillion:game:v1": fixture("game-daily-done")]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: today) == .done(depthMeters: 1950, streak: nil))
}

@Test func testGameInProgressIsNotDone() {
    let storage = ["krillion:game:v1": fixture("game-daily-in-progress")]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: today) == .notDone)
}

@Test func testSignedInOwnerUsesPrefixedKeys() {
    let storage = [
        "krillion:account-owner:v1": "uid 7",
        "krillion:account:uid%207:krillion:stats:v1": fixture("stats-daily-done"),
        "krillion:stats:v1": "{\"history\":{}}",
    ]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: today) == .done(depthMeters: 4320, streak: 6))
}

@Test func testWatchedKeys() {
    #expect(DiveDetector.isWatched("krillion:stats:v1"))
    #expect(DiveDetector.isWatched("krillion:stats:v2"))
    #expect(DiveDetector.isWatched("krillion:account:abc:krillion:game:v1"))
    #expect(DiveDetector.isWatched("krillion:account-owner:v1"))
    #expect(!DiveDetector.isWatched("krillion-party-name"))
}

@Test func testOtherStorageVersionIsUnknown() {
    let storage = ["krillion:stats:v2": fixture("stats-daily-done")]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: today) == .unknown)
}

@Test func testOwnerWithoutPrefixedStatsIsUnknown() {
    let storage = ["krillion:account-owner:v1": "uid7", "krillion:stats:v1": fixture("stats-daily-done")]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: today) == .unknown)
}

@Test func testUnrelatedKrillionKeysStillNotDone() {
    let storage = ["krillion:player:v1": "\"p-1\"", "krillion:announcements:seen:v1": "[]"]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: today) == .notDone)
}

@Test func testOnlyAnOldUnfinishedGameIsNotDone() {
    let storage = ["krillion:game:v1": fixture("game-daily-in-progress")]
    #expect(DiveDetector.evaluate(storage: storage, diveDate: "2026-11-17") == .notDone)
}
