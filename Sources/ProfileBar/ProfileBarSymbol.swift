import AppKit

enum ProfileBarSymbol {
    static func image(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { bounds in
            let scale = bounds.width / 18
            NSColor.labelColor.setFill()
            panel(NSRect(x: 1, y: 3, width: 4.25, height: 12), scale: scale).fill()
            panel(NSRect(x: 6.25, y: 1.5, width: 5.5, height: 15), scale: scale).fill()
            panel(NSRect(x: 12.75, y: 3, width: 4.25, height: 12), scale: scale).fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func panel(_ rect: NSRect, scale: CGFloat) -> NSBezierPath {
        let scaled = NSRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        return NSBezierPath(roundedRect: scaled, xRadius: 1.5 * scale, yRadius: 1.5 * scale)
    }
}
