import CoreGraphics

/// Where the puffer's window goes: centred under the menu-bar icon, kept on screen.
public enum PanelPlacement {
    static let margin: CGFloat = 8
    static let gapBelowIcon: CGFloat = 4

    /// Top-left point for a window of `panelWidth`, under an icon whose bottom edge is `anchorMinY`.
    public static func topLeft(anchorMidX: CGFloat, anchorMinY: CGFloat, panelWidth: CGFloat,
                               visible: CGRect) -> CGPoint {
        let lowest = visible.minX + margin
        let highest = visible.maxX - panelWidth - margin
        let x = min(max(anchorMidX - panelWidth / 2, lowest), max(lowest, highest))
        return CGPoint(x: x, y: anchorMinY - gapBelowIcon)
    }
}
