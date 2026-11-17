import Foundation
import Testing
@testable import PufferCore

@Test func testRoomCodeNormalisation() {
    #expect(RoomCode(" abcd ")?.value == "ABCD")
    #expect(RoomCode("WxYz")?.value == "WXYZ")
    #expect(RoomCode("ABCDE") == nil)
    #expect(RoomCode("AB1D") == nil)
    #expect(RoomCode("ÄBCD") == nil)
    #expect(RoomCode("") == nil)
}

@Test func testDeepLinkParsing() {
    #expect(DeepLink.parse(URL(string: "pufferpal://party/wxyz")!) == .party(RoomCode("WXYZ")))
    #expect(DeepLink.parse(URL(string: "pufferpal://party")!) == .party(nil))
    #expect(DeepLink.parse(URL(string: "pufferpal://party/")!) == .party(nil))
    #expect(DeepLink.parse(URL(string: "pufferpal://party/WX")!) == nil)
    #expect(DeepLink.parse(URL(string: "pufferpal://dive")!) == .dive)
    #expect(DeepLink.parse(URL(string: "pufferpal://nope")!) == nil)
    #expect(DeepLink.parse(URL(string: "https://party/ABCD")!) == nil)
}

@Test func testKrillionURLs() {
    let last = RoomCode("WXYZ")
    #expect(DeepLink.party(nil).krillionURL(lastRoom: last).absoluteString == "https://krillion.io/party/WXYZ")
    #expect(DeepLink.party(nil).krillionURL(lastRoom: nil).absoluteString == "https://krillion.io/party")
    #expect(DeepLink.party(RoomCode("ABCD")).krillionURL(lastRoom: last).absoluteString == "https://krillion.io/party/ABCD")
    #expect(DeepLink.dive.krillionURL(lastRoom: last).absoluteString == "https://krillion.io/")
}

@Test func testRoomFromKrillionURL() {
    #expect(RoomCode(fromKrillionURL: URL(string: "https://krillion.io/party/QRST")!) == RoomCode("QRST"))
    #expect(RoomCode(fromKrillionURL: URL(string: "https://krillion.io/party")!) == nil)
    #expect(RoomCode(fromKrillionURL: URL(string: "https://evil.io/party/QRST")!) == nil)
}
