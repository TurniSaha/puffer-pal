import Foundation

/// `pufferpal://party/CODE`, `pufferpal://party` (last room) and `pufferpal://dive`.
public enum DeepLink: Equatable, Sendable {
    case party(RoomCode?)
    case dive

    public static let scheme = "pufferpal"

    public static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch url.host?.lowercased() {
        case "dive":
            return parts.isEmpty ? .dive : nil
        case "party":
            if parts.isEmpty { return .party(nil) }
            guard parts.count == 1, let code = RoomCode(parts[0]) else { return nil }
            return .party(code)
        default:
            return nil
        }
    }

    public func krillionURL(lastRoom: RoomCode?) -> URL {
        switch self {
        case .dive: return KrillionURL.dive
        case .party(let code?): return KrillionURL.room(code)
        case .party(nil): return lastRoom.map(KrillionURL.room) ?? KrillionURL.party
        }
    }
}
