import Foundation

/// Builds a Date from wall-clock parts in a named zone.
func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0, zone: String) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: zone)!
    return cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
}

func utc(_ iso: String) -> Date {
    ISO8601DateFormatter().date(from: iso)!
}

let chicago = TimeZone(identifier: "America/Chicago")!
