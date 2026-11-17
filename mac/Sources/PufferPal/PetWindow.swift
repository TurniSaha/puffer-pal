import AppKit
import QuartzCore

/// The fish pet: a small borderless window that floats above everything, on every desktop.
/// Click opens the game, drag moves it, right-click shows the puffer menu.
final class PetWindow: NSPanel {
    var onClick: () -> Void = {}
    var onMoved: (NSPoint) -> Void = { _ in }
    var menuProvider: () -> NSMenu = { NSMenu() }

    private let petView = PetView(frame: NSRect(origin: .zero, size: PetArt.size))
    private var mood: PufferMood?

    init() {
        super.init(contentRect: NSRect(origin: .zero, size: PetArt.size),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        contentView = petView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func setMood(_ newMood: PufferMood, tooltip: String) {
        petView.toolTip = tooltip
        guard newMood != mood else { return }
        let wasPuffed = mood == .puffed
        mood = newMood
        petView.art.contents = PetArt.image(for: newMood)
        if newMood == .puffed && !wasPuffed { petView.wiggle() }
    }

    fileprivate func clicked() { onClick() }
    fileprivate func moved() { onMoved(frame.origin) }
    fileprivate func menu() -> NSMenu { menuProvider() }
}

private final class PetView: NSView {
    let art = CALayer()
    private var pet: PetWindow? { window as? PetWindow }
    private var dragStart: NSPoint?
    private var originAtStart: NSPoint = .zero
    private var dragged = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        art.frame = bounds.insetBy(dx: 0, dy: 3)
        art.contentsGravity = .resizeAspect
        layer?.addSublayer(art)
        bob()
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Clicks only land on the fish, not the transparent square around it.
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let fish = bounds.insetBy(dx: 4, dy: 10)
        return NSBezierPath(ovalIn: fish).contains(local) ? self : nil
    }

    // MARK: Motion

    private func bob() {
        let a = CABasicAnimation(keyPath: "transform.translation.y")
        a.fromValue = -2.5
        a.toValue = 2.5
        a.duration = 1.8
        a.autoreverses = true
        a.repeatCount = .infinity
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        art.add(a, forKey: "bob")
    }

    func wiggle() {
        let a = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        a.values = [0, 0.22, -0.22, 0.15, -0.15, 0]
        a.duration = 0.6
        art.add(a, forKey: "wiggle")
    }

    override func mouseEntered(with event: NSEvent) { wiggle() }

    // MARK: Click and drag

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        originAtStart = window?.frame.origin ?? .zero
        dragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, let window else { return }
        let now = NSEvent.mouseLocation
        let dx = now.x - start.x, dy = now.y - start.y
        if !dragged && hypot(dx, dy) < 3 { return }
        dragged = true
        window.setFrameOrigin(NSPoint(x: originAtStart.x + dx, y: originAtStart.y + dy))
    }

    override func mouseUp(with event: NSEvent) {
        defer { dragStart = nil }
        if dragged { pet?.moved() } else { pet?.clicked() }
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = pet?.menu() else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
}
