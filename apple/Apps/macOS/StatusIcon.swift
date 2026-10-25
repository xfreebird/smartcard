import AppKit

/// Menu-bar glyph with the connection dot (docs/10 §0.2b, UX-11): green while a card is inserted, gray otherwise.
///
/// Like most menu-bar extras (GitHub's, for one) the glyph is a solid disc with the symbol cut out of it: the disc is
/// drawn in `labelColor` (resolved at draw time, so it follows light/dark/tinted menu bars) and the `signature` symbol
/// is punched through, so the menu bar shows through it. Only the badge dot carries color, set off by a clear ring.
enum StatusIcon {
    static func image(connected: Bool) -> NSImage {
        let size = NSSize(width: 20, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            let disc = NSRect(x: 0.5, y: 1, width: 16, height: 16)
            NSColor.labelColor.setFill()
            NSBezierPath(ovalIn: disc).fill()

            let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .black)
            if let glyph = NSImage(systemSymbolName: "signature", accessibilityDescription: nil)?
                .withSymbolConfiguration(config) {
                // bold strokes, scaled into the disc with a margin (the symbol image is wider than the disc)
                let width: CGFloat = 12, height = width * glyph.size.height / glyph.size.width
                let rect = NSRect(x: disc.midX - width / 2, y: disc.midY - height / 2, width: width, height: height)
                glyph.draw(in: rect, from: .zero, operation: .destinationOut, fraction: 1)
            }

            let dot = NSRect(x: 12.5, y: 0.5, width: 7, height: 7)
            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(ovalIn: dot.insetBy(dx: -1.5, dy: -1.5)).fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            (connected ? NSColor.systemGreen : NSColor.systemGray).setFill()
            NSBezierPath(ovalIn: dot).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
