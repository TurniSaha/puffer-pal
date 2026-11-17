import Foundation

/// A Puffer Party room code: exactly four letters A–Z.
public struct RoomCode: Equatable, Hashable, Sendable {
    public let value: String

    public init?(_ raw: String) {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let isAsciiLetters = code.unicodeScalars.allSatisfy { ("A"..."Z").contains($0) }
        guard code.count == 4, isAsciiLetters else { return nil }
        value = code
    }

    /// The room in a `https://krillion.io/party/CODE` URL, if that's what it is.
    public init?(fromKrillionURL url: URL) {
        guard url.host == KrillionURL.host else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2, parts[0] == "party" else { return nil }
        self.init(parts[1])
    }
}

public enum KrillionURL {
    public static let host = "krillion.io"
    public static let dive = URL(string: "https://krillion.io/")!
    public static let party = URL(string: "https://krillion.io/party")!
    public static func room(_ code: RoomCode) -> URL {
        URL(string: "https://krillion.io/party/\(code.value)")!
    }
}
