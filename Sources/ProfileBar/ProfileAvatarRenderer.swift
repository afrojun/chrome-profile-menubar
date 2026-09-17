import AppKit

enum ProfileAvatarRenderer {
    static func image(for profile: ChromeProfile, size: CGFloat = 20) -> NSImage {
        let pictureURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Google/Chrome")
            .appendingPathComponent(profile.directory)
            .appendingPathComponent("Google Profile Picture.png")
        let source = NSImage(contentsOf: pictureURL) ?? monogram(for: profile)
        let image = circularImage(from: source, size: size)
        image.isTemplate = false
        return image
    }

    private static func circularImage(from source: NSImage, size: CGFloat) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { bounds in
            guard source.size.width > 0, source.size.height > 0 else { return false }
            let avatarRect = bounds.insetBy(dx: 1, dy: 1)
            let cropSide = min(source.size.width, source.size.height)
            let sourceRect = NSRect(
                x: (source.size.width - cropSide) / 2,
                y: (source.size.height - cropSide) / 2,
                width: cropSide,
                height: cropSide
            )

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current?.imageInterpolation = .high
            NSBezierPath(ovalIn: avatarRect).addClip()
            source.draw(
                in: avatarRect,
                from: sourceRect,
                operation: .sourceOver,
                fraction: 1,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high]
            )
            NSGraphicsContext.restoreGraphicsState()

            let border = NSBezierPath(ovalIn: avatarRect.insetBy(dx: 0.35, dy: 0.35))
            border.lineWidth = max(0.7, size / 28)
            NSColor.separatorColor.withAlphaComponent(0.8).setStroke()
            border.stroke()
            return true
        }
    }

    private static func monogram(for profile: ChromeProfile) -> NSImage {
        NSImage(size: NSSize(width: 128, height: 128), flipped: false) { bounds in
            let palette: [NSColor] = [
                .systemBlue, .systemPurple, .systemGreen, .systemOrange, .systemPink, .systemTeal,
            ]
            let colorIndex = profile.directory.utf8.reduce(0) { ($0 * 31 + Int($1)) % palette.count }
            palette[colorIndex].setFill()
            bounds.fill()

            let initial = String(profile.name.prefix(1)).uppercased()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 72, weight: .medium),
                .foregroundColor: NSColor.white,
            ]
            let size = initial.size(withAttributes: attributes)
            initial.draw(
                at: NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2),
                withAttributes: attributes
            )
            return true
        }
    }
}
