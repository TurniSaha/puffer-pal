import Foundation

/// What the puffer knows about today's dive; shared with the Claude Code mod via status.json.
public struct DiveStatus: Codable, Equatable, Sendable {
    public var diveDate: String
    public var diveDone: Bool?
    public var depthMeters: Int?
    public var streak: Int?
    public var lastRoom: String?
    /// The app's local reminder hour; nil = reminders off. The Claude mod nudges at the same time.
    public var reminderHour: Int?
    public var updatedAt: String

    public init(diveDate: String, diveDone: Bool?, depthMeters: Int? = nil, streak: Int? = nil,
                lastRoom: String? = nil, reminderHour: Int? = nil, updatedAt: String) {
        self.diveDate = diveDate
        self.diveDone = diveDone
        self.depthMeters = depthMeters
        self.streak = streak
        self.lastRoom = lastRoom
        self.reminderHour = reminderHour
        self.updatedAt = updatedAt
    }

    /// nil = unknown. A status about another day says nothing was done today.
    public func isDone(on day: String) -> Bool? {
        guard diveDate == day else { return false }
        return diveDone
    }

    // Always write every key (nulls included) so the file's shape matches the spec.
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(diveDate, forKey: .diveDate)
        try c.encode(diveDone, forKey: .diveDone)
        try c.encode(depthMeters, forKey: .depthMeters)
        try c.encode(streak, forKey: .streak)
        try c.encode(lastRoom, forKey: .lastRoom)
        try c.encode(reminderHour, forKey: .reminderHour)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

public struct StatusStore: Sendable {
    public let url: URL

    public init(url: URL) { self.url = url }

    public static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PufferPal/status.json")
    }

    /// nil when the file is missing or isn't a valid status.
    public func read() -> DiveStatus? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DiveStatus.self, from: data)
    }

    /// Writes via a temp file and rename, creating the folder if needed.
    public func write(_ status: DiveStatus) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(status).write(to: url, options: .atomic)
    }

    public static func timestamp(_ date: Date = Date()) -> String {
        let f = ISO8601DateFormatter()
        f.timeZone = .current
        return f.string(from: date)
    }
}
