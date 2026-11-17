// Draws the app icon (an original puffer on a sea-blue tile) as a 1024px PNG.
import AppKit

let out = CommandLine.arguments[1]
let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    let tile = NSBezierPath(roundedRect: rect.insetBy(dx: 80, dy: 80), xRadius: 190, yRadius: 190)
    NSGradient(starting: NSColor(red: 0.16, green: 0.62, blue: 0.76, alpha: 1),
               ending: NSColor(red: 0.04, green: 0.20, blue: 0.38, alpha: 1))!.draw(in: tile, angle: -90)
    let c = NSPoint(x: 560, y: 500), r = 230.0
    NSColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1).set()
    let spikes = NSBezierPath(); spikes.lineWidth = 26; spikes.lineCapStyle = .round
    for i in 0..<14 {
        let a = Double(i) / 14 * 2 * .pi
        spikes.move(to: NSPoint(x: c.x + cos(a) * r * 0.9, y: c.y + sin(a) * r * 0.9))
        spikes.line(to: NSPoint(x: c.x + cos(a) * (r + 70), y: c.y + sin(a) * (r + 70)))
    }
    spikes.stroke()
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: c.x - r + 30, y: c.y)); tail.line(to: NSPoint(x: 190, y: c.y + 130))
    tail.line(to: NSPoint(x: 190, y: c.y - 130)); tail.close(); tail.fill()
    NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)).fill()
    NSColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1).set()
    NSBezierPath(ovalIn: NSRect(x: c.x - r * 0.7, y: c.y - r * 0.85, width: r * 1.4, height: r * 0.8)).fill()
    NSColor.white.set(); NSBezierPath(ovalIn: NSRect(x: c.x + 50, y: c.y + 40, width: 110, height: 110)).fill()
    NSColor.black.set(); NSBezierPath(ovalIn: NSRect(x: c.x + 95, y: c.y + 70, width: 55, height: 55)).fill()
    return true
}
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
