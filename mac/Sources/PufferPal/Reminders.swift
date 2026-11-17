import Foundation
import PufferCore
import UserNotifications

/// Posts the Daily Dive reminders and reports when one is clicked.
final class Reminders: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var isAuthorized = false
    var onOpenDive: () -> Void = {}

    func start() {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { NSLog("Puffer Pal: notification permission error: \(error)") }
            DispatchQueue.main.async { self.isAuthorized = granted }
            if !granted { NSLog("Puffer Pal: app notifications refused; using the system fallback") }
        }
    }

    static func text(for kind: ReminderKind, statusKnown: Bool) -> String {
        switch kind {
        case .last: return "Last call: Daily Dive resets at 11pm 🐡"
        case .main: return statusKnown ? "Daily Dive is waiting 🐡" : "Done your Daily Dive yet? 🐡"
        }
    }

    /// Returns false when the reminder couldn't be handed to macOS, so it can be retried.
    func post(_ kind: ReminderKind, statusKnown: Bool) -> Bool {
        let body = Self.text(for: kind, statusKnown: statusKnown)
        guard isAuthorized else { return postViaSystem(body) }
        let content = UNMutableNotificationContent()
        content.title = "Puffer Pal"
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: "dive-\(kind.rawValue)", content: content, trigger: nil)
        center.add(request) { error in
            if let error { NSLog("Puffer Pal: couldn't post reminder: \(error)") }
        }
        return true
    }

    /// An ad-hoc signed app may be refused notifications; macOS's own `display notification`
    /// still reaches Notification Center, filed under Script Editor (clicking opens Script Editor).
    private func postViaSystem(_ body: String) -> Bool {
        let escaped = body.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "display notification \"\(escaped)\" with title \"Puffer Pal\" sound name \"Glass\""]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("Puffer Pal: fallback notification failed: \(error)")
            return false
        }
        if process.terminationStatus != 0 {
            NSLog("Puffer Pal: fallback notification exited \(process.terminationStatus)")
        }
        return process.terminationStatus == 0
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler done: @escaping () -> Void) {
        DispatchQueue.main.async { self.onOpenDive() }
        done()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler done: @escaping (UNNotificationPresentationOptions) -> Void) {
        done([.banner, .sound])
    }
}
