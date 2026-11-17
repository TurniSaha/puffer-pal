import Foundation

public enum ReminderKind: String, Equatable, Hashable, Codable, Sendable {
    case main, last
}

/// Decides when the Daily Dive reminders fire. Reminder hours are local wall-clock
/// hours; a reminder only counts for the dive day it falls in, and never after reset.
public struct ReminderPlanner: Sendable {
    public let reminderHour: Int?
    public let lastHour: Int
    public let localZone: TimeZone

    public init(reminderHour: Int?, lastHour: Int = 22, localZone: TimeZone) {
        self.reminderHour = reminderHour
        self.lastHour = lastHour
        self.localZone = localZone
    }

    /// The reminder to send now, if any. `alreadySent` holds kinds sent for the current dive day.
    /// When both are overdue only `.last` fires, so waking from sleep never sends a burst.
    public func due(now: Date, status: DiveStatus?, alreadySent: Set<ReminderKind>) -> ReminderKind? {
        guard needsReminder(now: now, status: status) else { return nil }
        let passed = fireTimes(for: now).filter { $0.time <= now }
        guard let latest = passed.last, !alreadySent.contains(latest.kind) else { return nil }
        return latest.kind
    }

    /// The next future time a reminder could fire for the current dive day, for scheduling.
    public func nextFire(after now: Date, status: DiveStatus?, alreadySent: Set<ReminderKind>) -> Date? {
        guard needsReminder(now: now, status: status) else { return nil }
        return fireTimes(for: now)
            .first { $0.time > now && !alreadySent.contains($0.kind) }?
            .time
    }

    private func needsReminder(now: Date, status: DiveStatus?) -> Bool {
        let day = DiveClock.diveDate(at: now)
        return status?.isDone(on: day) != true
    }

    /// Reminder times on the local calendar day of `now`, kept only if they fall in the
    /// same dive day as `now` (so before the next reset), in firing order.
    private func fireTimes(for now: Date) -> [(kind: ReminderKind, time: Date)] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = localZone
        let day = DiveClock.diveDate(at: now)
        let hours: [(ReminderKind, Int?)] = [(.main, reminderHour), (.last, lastHour)]
        return hours.compactMap { kind, hour in
            guard let hour,
                  let time = cal.date(bySettingHour: hour, minute: 0, second: 0, of: now),
                  DiveClock.diveDate(at: time) == day
            else { return nil }
            return (kind, time)
        }
    }
}

/// The hours offered in the "Remind me at" menu: every hour of the day.
public enum ReminderHours {
    public static let all = Array(0...23)

    /// "12am", "9am", "12pm", "7pm".
    public static func label(_ hour: Int) -> String {
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        return "\(twelve)\(hour < 12 ? "am" : "pm")"
    }
}
