import Foundation
import Testing
@testable import PufferCore

private func tempURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("puffer-\(UUID().uuidString)/nested/status.json")
}

private let sample = DiveStatus(
    diveDate: "2026-11-16", diveDone: true, depthMeters: 4320, streak: 6,
    lastRoom: "WXYZ", reminderHour: 20, updatedAt: "2026-11-16T20:02:11-06:00")

@Test func testRoundTrip() throws {
    let store = StatusStore(url: tempURL())
    try store.write(sample)
    #expect(store.read() == sample)
}

@Test func testMissingFileReadsNil() {
    #expect(StatusStore(url: tempURL()).read() == nil)
}

@Test func testCorruptFileReadsNil() throws {
    let url = tempURL()
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("{not json".utf8).write(to: url)
    #expect(StatusStore(url: url).read() == nil)
}

@Test func testWriteCreatesFolder() throws {
    let url = tempURL()
    try StatusStore(url: url).write(sample)
    #expect(FileManager.default.fileExists(atPath: url.path))
}

@Test func testJSONKeysMatchSpec() throws {
    let url = tempURL()
    try StatusStore(url: url).write(sample)
    let obj = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
    #expect(Set(obj.keys) == ["diveDate", "diveDone", "depthMeters", "streak", "lastRoom", "reminderHour", "updatedAt"])
}

@Test func testUnknownWritesNullDone() throws {
    let url = tempURL()
    try StatusStore(url: url).write(DiveStatus(diveDate: "2026-11-16", diveDone: nil, updatedAt: "x"))
    let text = try String(contentsOf: url, encoding: .utf8)
    #expect(text.contains("\"diveDone\" : null"))
}

@Test func testIsDoneOnDate() {
    #expect(sample.isDone(on: "2026-11-16") == true)
    #expect(sample.isDone(on: "2026-11-17") == false)
    let unknown = DiveStatus(diveDate: "2026-11-16", diveDone: nil, updatedAt: "x")
    #expect(unknown.isDone(on: "2026-11-16") == nil)
}

@Test func testDefaultURL() {
    #expect(StatusStore.defaultURL.path.hasSuffix("Library/Application Support/PufferPal/status.json"))
}

@Test func testOlderFileWithoutReminderHourStillReads() throws {
    let url = tempURL()
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(#"{"diveDate":"2026-11-16","diveDone":false,"updatedAt":"x"}"#.utf8).write(to: url)
    #expect(StatusStore(url: url).read()?.reminderHour == nil)
}
