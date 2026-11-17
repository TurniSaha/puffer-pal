import CoreGraphics

/// Where the fish pet sits on screen. Coordinates are AppKit's: origin bottom-left.
public enum PetPlacement {
    static let cornerInset: CGFloat = 20

    /// Bottom-right corner of `visible`, a little in from the edges.
    public static func defaultOrigin(petSize: CGSize, visible: CGRect) -> CGPoint {
        CGPoint(x: visible.maxX - petSize.width - cornerInset, y: visible.minY + cornerInset)
    }

    /// The saved spot, pulled fully onto the screen it overlaps most; the default corner of
    /// `main` when nothing was saved or that screen is gone.
    public static func restore(saved: CGPoint?, petSize: CGSize, screens: [CGRect], main: CGRect) -> CGPoint {
        guard let saved else { return defaultOrigin(petSize: petSize, visible: main) }
        let rect = CGRect(origin: saved, size: petSize)
        let overlap = { (screen: CGRect) -> CGFloat in
            let i = screen.intersection(rect)
            return i.isNull ? 0 : i.width * i.height
        }
        guard let screen = screens.max(by: { overlap($0) < overlap($1) }), overlap(screen) > 0 else {
            return defaultOrigin(petSize: petSize, visible: main)
        }
        return CGPoint(x: clamp(saved.x, screen.minX, screen.maxX - petSize.width),
                       y: clamp(saved.y, screen.minY, screen.maxY - petSize.height))
    }

    static func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        min(max(value, low), max(low, high))
    }
}

extension PanelPlacement {
    /// Top-left point for the game window opened from the pet: right edges lined up, above
    /// the pet when there's room, else below it, else as high as the screen allows.
    public static func topLeft(nearPet pet: CGRect, panelSize: CGSize, visible: CGRect) -> CGPoint {
        let x = PetPlacement.clamp(pet.maxX - panelSize.width,
                                   visible.minX + margin, visible.maxX - panelSize.width - margin)
        let top = visible.maxY - margin
        let bottom = visible.minY + margin
        let y: CGFloat
        if top - (pet.maxY + gapBelowIcon * 2) >= panelSize.height {
            y = pet.maxY + gapBelowIcon * 2 + panelSize.height
        } else if (pet.minY - gapBelowIcon * 2) - bottom >= panelSize.height {
            y = pet.minY - gapBelowIcon * 2
        } else {
            y = top
        }
        return CGPoint(x: x, y: y)
    }
}
