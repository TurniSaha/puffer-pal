import Foundation

// How Krillion records a Daily Dive (read from krillion.io's JS bundle, 2026-11-16):
//
// - `krillion:stats:v1` = { history: { "YYYY-MM-DD": { dayNumber, score, tiers[7], results? } },
//   gamesPlayed, totalScore, bestScore, currentStreak, maxStreak, lastPlayedDate }.
//   A finished daily dive for a New York date D means `history[D]` exists with a numeric score.
// - `krillion:game:v1` = the current daily game { date, phase, results[] }. Krillion's own
//   "finished" test is phase == "done" && results.length == 7 (ROUNDS_PER_DAY).
// - Archive games go to `krillion-archive-done` / `krillion-archive-N`, packs and unlimited to
//   their own keys, so they never touch the daily history.
// - Depth shown in the game is 10 × score, in meters.
// - With a signed-in account, keys are prefixed `krillion:account:<encodeURIComponent(owner)>:`,
//   where owner is the raw value of `krillion:account-owner:v1`. Guests have no prefix.

public enum DiveReading: Equatable, Sendable {
    case done(depthMeters: Int?, streak: Int?)
    case notDone
    case unknown
}

public enum DiveDetector {
    public static let ownerKey = "krillion:account-owner:v1"
    public static let statsSuffix = "krillion:stats:v1"
    public static let gameSuffix = "krillion:game:v1"
    static let roundsPerDay = 7
    static let metersPerPoint = 10

    /// Keys the web bridge should snapshot from localStorage: every `krillion:` key, so a
    /// renamed or re-versioned key shows up as "unknown" instead of looking like a fresh player.
    public static func isWatched(_ key: String) -> Bool {
        key.hasPrefix("krillion:")
    }

    public static func evaluate(storage: [String: String], diveDate: String) -> DiveReading {
        let prefix = keyPrefix(owner: storage[ownerKey])
        if let raw = storage[prefix + statsSuffix] {
            switch readStats(raw, diveDate: diveDate) {
            case .notDone: break // the game state may be finished before stats land
            case let reading: return reading
            }
        }
        if let raw = storage[prefix + gameSuffix], let reading = readGame(raw, diveDate: diveDate) {
            return reading
        }
        let expected: Set = [prefix + statsSuffix, prefix + gameSuffix]
        let elsewhere = storage.keys.contains { !expected.contains($0) && looksLikeProgress($0) }
        if storage[prefix + statsSuffix] == nil, elsewhere {
            // Progress is stored somewhere we don't read (new version, other owner prefix).
            return .unknown
        }
        return .notDone
    }

    private static func looksLikeProgress(_ key: String) -> Bool {
        key.range(of: #"krillion:(stats|game):v\d+$"#, options: .regularExpression) != nil
    }

    private static func keyPrefix(owner: String?) -> String {
        guard let owner, !owner.isEmpty else { return "" }
        // Matches JS encodeURIComponent's unreserved set.
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
        let encoded = owner.addingPercentEncoding(withAllowedCharacters: allowed) ?? owner
        return "krillion:account:\(encoded):"
    }

    private static func json(_ raw: String) -> [String: Any]? {
        guard let data = raw.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static func readStats(_ raw: String, diveDate: String) -> DiveReading {
        guard let stats = json(raw), let history = stats["history"] as? [String: Any] else {
            return .unknown
        }
        guard let entry = history[diveDate] else { return .notDone }
        guard let day = entry as? [String: Any], let score = day["score"] as? Int else {
            return .unknown
        }
        return .done(depthMeters: score * metersPerPoint, streak: stats["currentStreak"] as? Int)
    }

    /// nil when the game state says nothing about today (missing, other day, unreadable).
    private static func readGame(_ raw: String, diveDate: String) -> DiveReading? {
        guard let game = json(raw), game["date"] as? String == diveDate else { return nil }
        guard game["phase"] as? String == "done",
              let results = game["results"] as? [[String: Any]],
              results.count == roundsPerDay
        else { return .notDone }
        let points = results.compactMap { $0["score"] as? Int }.reduce(0, +)
        return .done(depthMeters: points * metersPerPoint, streak: nil)
    }
}
