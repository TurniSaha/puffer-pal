import Foundation

/// Krillion's Daily Dive day runs midnight to midnight, New York time.
public enum DiveClock {
    public static let zone = TimeZone(identifier: "America/New_York")!

    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        return cal
    }

    /// The dive date ("yyyy-MM-dd", New York) that `date` falls in.
    public static func diveDate(at date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// The next 00:00 New York strictly after `date`.
    public static func nextReset(after date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    }
}
