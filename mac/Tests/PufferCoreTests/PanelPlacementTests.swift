import CoreGraphics
import Testing
@testable import PufferCore

private let screen = CGRect(x: 0, y: 0, width: 1512, height: 944) // visible frame, menu bar excluded

@Test func testCentredUnderIconWhenItFits() {
    let p = PanelPlacement.topLeft(anchorMidX: 700, anchorMinY: 944, panelWidth: 440, visible: screen)
    #expect(p == CGPoint(x: 480, y: 940))
}

@Test func testClampedAtRightEdge() {
    let p = PanelPlacement.topLeft(anchorMidX: 1490, anchorMinY: 944, panelWidth: 440, visible: screen)
    #expect(p.x == CGFloat(1512 - 440 - 8))
}

@Test func testClampedAtLeftEdge() {
    let p = PanelPlacement.topLeft(anchorMidX: 30, anchorMinY: 944, panelWidth: 440, visible: screen)
    #expect(p.x == CGFloat(8))
}

@Test func testSecondScreenOffset() {
    let right = CGRect(x: 1512, y: 0, width: 1920, height: 1050)
    let p = PanelPlacement.topLeft(anchorMidX: 3420, anchorMinY: 1050, panelWidth: 440, visible: right)
    #expect(p.x == CGFloat(1512 + 1920 - 440 - 8))
}
