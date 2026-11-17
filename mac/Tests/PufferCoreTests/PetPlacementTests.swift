import CoreGraphics
import Testing
@testable import PufferCore

private let laptop = CGRect(x: 0, y: 0, width: 1512, height: 944) // visible frame, menu bar excluded
private let external = CGRect(x: 1512, y: 0, width: 1920, height: 1050)
private let pet = CGSize(width: 80, height: 80)

@Test func testDefaultSpotIsBottomRight() {
    #expect(PetPlacement.defaultOrigin(petSize: pet, visible: laptop) == CGPoint(x: 1512 - 80 - 20, y: 20))
}

@Test func testRestoreKeepsASavedSpotThatIsOnScreen() {
    let saved = CGPoint(x: 300, y: 500)
    #expect(PetPlacement.restore(saved: saved, petSize: pet, screens: [laptop], main: laptop) == saved)
}

@Test func testRestoreKeepsASpotOnTheSecondScreen() {
    let saved = CGPoint(x: 2000, y: 600)
    #expect(PetPlacement.restore(saved: saved, petSize: pet, screens: [laptop, external], main: laptop) == saved)
}

@Test func testRestoreFallsBackWhenTheScreenIsGone() {
    let saved = CGPoint(x: 2000, y: 600) // external display unplugged
    #expect(PetPlacement.restore(saved: saved, petSize: pet, screens: [laptop], main: laptop)
        == PetPlacement.defaultOrigin(petSize: pet, visible: laptop))
}

@Test func testRestorePullsAHalfHiddenPetBackOnScreen() {
    let saved = CGPoint(x: 1480, y: -30) // dragged past the bottom-right corner
    #expect(PetPlacement.restore(saved: saved, petSize: pet, screens: [laptop], main: laptop)
        == CGPoint(x: 1512 - 80, y: 0))
}

@Test func testRestoreWithNothingSavedUsesTheDefault() {
    #expect(PetPlacement.restore(saved: nil, petSize: pet, screens: [laptop], main: laptop)
        == PetPlacement.defaultOrigin(petSize: pet, visible: laptop))
}

private let panel = CGSize(width: 440, height: 760)

@Test func testPanelOpensAboveAPetInTheBottomCorner() {
    let petFrame = CGRect(x: 1412, y: 20, width: 80, height: 80)
    let p = PanelPlacement.topLeft(nearPet: petFrame, panelSize: panel, visible: laptop)
    #expect(p == CGPoint(x: 1492 - 440, y: 100 + 8 + 760))
}

@Test func testPanelOpensBelowAPetNearTheTop() {
    let petFrame = CGRect(x: 100, y: 840, width: 80, height: 80)
    let p = PanelPlacement.topLeft(nearPet: petFrame, panelSize: panel, visible: laptop)
    #expect(p == CGPoint(x: 8, y: 840 - 8))
}

@Test func testPanelTooTallForEitherSideIsKeptOnScreen() {
    let petFrame = CGRect(x: 700, y: 430, width: 80, height: 80) // mid-screen, no full room above or below
    let p = PanelPlacement.topLeft(nearPet: petFrame, panelSize: panel, visible: laptop)
    #expect(p.y == CGFloat(944 - 8))
    #expect(p.x == CGFloat(780 - 440))
}
