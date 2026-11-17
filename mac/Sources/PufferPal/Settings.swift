import Foundation
import PufferCore

/// The app's small preferences, kept in UserDefaults (com.turnisaha.pufferpal).
struct Settings {
    static let defaultReminderHour = 19

    private let defaults = UserDefaults.standard
    private enum Key {
        static let reminderHour = "reminderHour"   // -1 = off
        static let lastRoom = "lastRoom"
        static let sentReminders = "sentReminders" // { diveDate: [kind] }
        static let petVisible = "petVisible"
        static let petOrigin = "petOrigin"         // [x, y] in screen points
    }

    var petVisible: Bool {
        get { defaults.object(forKey: Key.petVisible) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: Key.petVisible) }
    }

    var petOrigin: CGPoint? {
        get {
            guard let xy = defaults.array(forKey: Key.petOrigin) as? [Double], xy.count == 2 else { return nil }
            return CGPoint(x: xy[0], y: xy[1])
        }
        nonmutating set {
            defaults.set(newValue.map { [Double($0.x), Double($0.y)] }, forKey: Key.petOrigin)
        }
    }

    var reminderHour: Int? {
        get {
            guard defaults.object(forKey: Key.reminderHour) != nil else { return Self.defaultReminderHour }
            let hour = defaults.integer(forKey: Key.reminderHour)
            return (0...23).contains(hour) ? hour : nil
        }
        nonmutating set { defaults.set(newValue ?? -1, forKey: Key.reminderHour) }
    }

    var lastRoom: RoomCode? {
        get { defaults.string(forKey: Key.lastRoom).flatMap(RoomCode.init) }
        nonmutating set { defaults.set(newValue?.value, forKey: Key.lastRoom) }
    }

    func sentReminders(on day: String) -> Set<ReminderKind> {
        let all = defaults.dictionary(forKey: Key.sentReminders) as? [String: [String]] ?? [:]
        return Set((all[day] ?? []).compactMap(ReminderKind.init(rawValue:)))
    }

    /// Records a sent reminder, keeping only the current day's entries.
    func markSent(_ kind: ReminderKind, on day: String) {
        let kinds = sentReminders(on: day).union([kind]).map(\.rawValue).sorted()
        defaults.set([day: kinds], forKey: Key.sentReminders)
    }
}
