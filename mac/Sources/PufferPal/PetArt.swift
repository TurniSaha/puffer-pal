import AppKit

/// The desktop pet: an original colour pufferfish, drawn in code so it stays sharp at any scale.
enum PetArt {
    static let size = NSSize(width: 84, height: 84)

    private static let outline = NSColor(red: 0.36, green: 0.22, blue: 0.08, alpha: 1)
    private static let bodyTop = NSColor(red: 1.00, green: 0.80, blue: 0.25, alpha: 1)
    private static let bodyBottom = NSColor(red: 0.96, green: 0.58, blue: 0.16, alpha: 1)
    private static let belly = NSColor(red: 1.00, green: 0.95, blue: 0.78, alpha: 1)
    private static let spot = NSColor(red: 0.85, green: 0.47, blue: 0.10, alpha: 0.75)
    private static let fin = NSColor(red: 0.98, green: 0.62, blue: 0.20, alpha: 1)

    static func image(for mood: PufferMood) -> NSImage {
        NSImage(size: size, flipped: false) { _ in
            draw(mood: mood)
            return true
        }
    }

    private static func draw(mood: PufferMood) {
        let puffed = mood == .puffed
        let center = NSPoint(x: 44, y: 38)
        let rx: CGFloat = puffed ? 27 : 23
        let ry: CGFloat = puffed ? 25 : 19
        let body = NSRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)

        drawTail(center: center, rx: rx)
        if puffed { drawSpikes(center: center, rx: rx, ry: ry) }

        let bodyPath = NSBezierPath(ovalIn: body)
        NSGradient(starting: bodyTop, ending: bodyBottom)?.draw(in: bodyPath, angle: -90)
        NSGraphicsContext.saveGraphicsState()
        bodyPath.addClip()
        belly.setFill()
        NSBezierPath(ovalIn: NSRect(x: body.minX + 6, y: body.minY - ry * 0.5,
                                    width: rx * 1.7, height: ry * 1.1)).fill()
        spot.setFill()
        for (dx, dy, r) in [(-10.0, 9.0, 2.6), (-2.0, 14.0, 2.2), (-15.0, 0.0, 2.0), (5.0, 11.0, 1.8)] {
            NSBezierPath(ovalIn: NSRect(x: center.x + dx - r, y: center.y + dy - r, width: r * 2, height: r * 2)).fill()
        }
        NSGraphicsContext.restoreGraphicsState()
        outline.setStroke()
        bodyPath.lineWidth = 2
        bodyPath.stroke()

        drawSideFin(center: center)
        drawFace(center: center, rx: rx, mood: mood)
        if puffed { drawBadge(text: "!", color: .systemRed) }
        if mood == .calm { drawBubbles() }
    }

    private static func drawTail(center: NSPoint, rx: CGFloat) {
        let tail = NSBezierPath()
        let root = NSPoint(x: center.x - rx + 3, y: center.y)
        tail.move(to: root)
        tail.curve(to: NSPoint(x: 4, y: center.y + 13), controlPoint1: NSPoint(x: root.x - 6, y: center.y + 4),
                   controlPoint2: NSPoint(x: 8, y: center.y + 12))
        tail.curve(to: NSPoint(x: 4, y: center.y - 13), controlPoint1: NSPoint(x: 9, y: center.y + 3),
                   controlPoint2: NSPoint(x: 9, y: center.y - 3))
        tail.curve(to: root, controlPoint1: NSPoint(x: 8, y: center.y - 12),
                   controlPoint2: NSPoint(x: root.x - 6, y: center.y - 4))
        fin.setFill()
        tail.fill()
        outline.setStroke()
        tail.lineWidth = 2
        tail.stroke()
    }

    private static func drawSideFin(center: NSPoint) {
        let path = NSBezierPath()
        let root = NSPoint(x: center.x - 4, y: center.y - 3)
        path.move(to: root)
        path.curve(to: NSPoint(x: center.x - 14, y: center.y - 12), controlPoint1: NSPoint(x: center.x - 8, y: center.y - 2),
                   controlPoint2: NSPoint(x: center.x - 14, y: center.y - 6))
        path.curve(to: root, controlPoint1: NSPoint(x: center.x - 8, y: center.y - 13),
                   controlPoint2: NSPoint(x: center.x - 4, y: center.y - 8))
        fin.setFill()
        path.fill()
        outline.setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }

    private static func drawSpikes(center: NSPoint, rx: CGFloat, ry: CGFloat) {
        let spikes = NSBezierPath()
        for i in 0..<14 {
            let a = CGFloat(i) / 14 * 2 * .pi + 0.2
            let spread: CGFloat = 0.11
            let base1 = NSPoint(x: center.x + cos(a - spread) * rx * 0.96, y: center.y + sin(a - spread) * ry * 0.96)
            let base2 = NSPoint(x: center.x + cos(a + spread) * rx * 0.96, y: center.y + sin(a + spread) * ry * 0.96)
            let tip = NSPoint(x: center.x + cos(a) * (rx + 7), y: center.y + sin(a) * (ry + 7))
            spikes.move(to: base1)
            spikes.line(to: tip)
            spikes.line(to: base2)
            spikes.close()
        }
        belly.setFill()
        spikes.fill()
        outline.setStroke()
        spikes.lineWidth = 1.4
        spikes.stroke()
    }

    private static func drawFace(center: NSPoint, rx: CGFloat, mood: PufferMood) {
        let eye = NSPoint(x: center.x + rx * 0.45, y: center.y + 5)
        if mood == .calm {
            // Content, closed eye: a little upside-down U.
            let lid = NSBezierPath()
            lid.appendArc(withCenter: NSPoint(x: eye.x, y: eye.y - 1), radius: 4.5, startAngle: 20, endAngle: 160)
            outline.setStroke()
            lid.lineWidth = 2.2
            lid.lineCapStyle = .round
            lid.stroke()
        } else {
            let r: CGFloat = mood == .puffed ? 8 : 7
            NSColor.white.setFill()
            let white = NSBezierPath(ovalIn: NSRect(x: eye.x - r, y: eye.y - r, width: r * 2, height: r * 2))
            white.fill()
            outline.setStroke()
            white.lineWidth = 1.6
            white.stroke()
            let p: CGFloat = mood == .puffed ? 3 : 3.8
            NSColor.black.setFill()
            NSBezierPath(ovalIn: NSRect(x: eye.x + 1 - p, y: eye.y - p, width: p * 2, height: p * 2)).fill()
            NSColor.white.setFill()
            NSBezierPath(ovalIn: NSRect(x: eye.x + 1.5, y: eye.y + 1, width: 2, height: 2)).fill()
        }
        // Little pursed mouth at the front.
        let mouthX = center.x + rx - 2
        let mouth = NSBezierPath(ovalIn: NSRect(x: mouthX - 2.5, y: center.y - 7, width: 5, height: mood == .puffed ? 6 : 4))
        NSColor(red: 0.90, green: 0.35, blue: 0.30, alpha: 1).setFill()
        mouth.fill()
        outline.setStroke()
        mouth.lineWidth = 1.4
        mouth.stroke()
    }

    private static func drawBadge(text: String, color: NSColor) {
        let rect = NSRect(x: 62, y: 62, width: 20, height: 20)
        color.setFill()
        NSBezierPath(ovalIn: rect).fill()
        NSColor.white.setStroke()
        let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5))
        ring.lineWidth = 1.5
        ring.stroke()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .heavy), .foregroundColor: NSColor.white,
        ]
        let s = NSAttributedString(string: text, attributes: attrs)
        let sz = s.size()
        s.draw(at: NSPoint(x: rect.midX - sz.width / 2, y: rect.midY - sz.height / 2))
    }

    private static func drawBubbles() {
        let blue = NSColor(red: 0.45, green: 0.75, blue: 0.95, alpha: 0.9)
        for (x, y, r) in [(70.0, 60.0, 3.5), (76.0, 70.0, 2.6), (71.0, 78.0, 1.8)] {
            let b = NSBezierPath(ovalIn: NSRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            blue.setStroke()
            b.lineWidth = 1.5
            b.stroke()
        }
    }
}
