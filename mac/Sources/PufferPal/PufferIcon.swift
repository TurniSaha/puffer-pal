import AppKit

enum PufferMood {
    case plain   // dive not done, before reminder time
    case puffed  // dive not done (or unknown), reminder time or later
    case calm    // dive done today
}

/// An original little pufferfish, drawn as a monochrome template image for the menu bar.
enum PufferIcon {
    static let size = NSSize(width: 22, height: 18)

    static func image(for mood: PufferMood, tilt: CGFloat = 0) -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            ctx.translateBy(x: rect.midX, y: rect.midY)
            ctx.rotate(by: tilt)
            ctx.translateBy(x: -rect.midX, y: -rect.midY)
            draw(mood: mood)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func draw(mood: PufferMood) {
        NSColor.black.setFill()
        NSColor.black.setStroke()
        let radius: CGFloat = mood == .puffed ? 6.6 : 5.6
        let center = NSPoint(x: 12, y: 9)
        let body = NSBezierPath(ovalIn: NSRect(
            x: center.x - radius, y: center.y - radius * 0.9,
            width: radius * 2, height: radius * 1.8))
        body.fill()

        // Tail fin on the left.
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: center.x - radius + 1, y: center.y))
        tail.line(to: NSPoint(x: 1.5, y: center.y + 3.5))
        tail.line(to: NSPoint(x: 1.5, y: center.y - 3.5))
        tail.close()
        tail.fill()

        if mood == .puffed { drawSpikes(center: center, radius: radius) }

        // Eye: punched out of the body.
        NSGraphicsContext.current?.compositingOperation = .clear
        let eyeR: CGFloat = mood == .calm ? 0.9 : 1.4
        NSBezierPath(ovalIn: NSRect(x: center.x + radius * 0.35 - eyeR, y: center.y + 1.2 - eyeR,
                                    width: eyeR * 2, height: mood == .calm ? 0.9 : eyeR * 2)).fill()
        NSGraphicsContext.current?.compositingOperation = .sourceOver

        if mood == .puffed {
            // Alert dot, top right.
            NSBezierPath(ovalIn: NSRect(x: 18.5, y: 13.5, width: 3.5, height: 3.5)).fill()
        }
    }

    private static func drawSpikes(center: NSPoint, radius: CGFloat) {
        let spikes = NSBezierPath()
        spikes.lineWidth = 1.2
        for i in 0..<10 {
            let angle = CGFloat(i) / 10 * 2 * .pi + 0.3
            let inner = NSPoint(x: center.x + cos(angle) * radius * 0.95,
                                y: center.y + sin(angle) * radius * 0.85)
            let outer = NSPoint(x: center.x + cos(angle) * (radius + 2.2),
                                y: center.y + sin(angle) * (radius * 0.9 + 2.0))
            spikes.move(to: inner)
            spikes.line(to: outer)
        }
        spikes.stroke()
    }
}
