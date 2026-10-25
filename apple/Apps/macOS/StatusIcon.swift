import AppKit

/// Menu-bar glyph with the connection dot (docs/10 §0.2b, UX-11): green while a card is inserted, gray otherwise.
///
/// HIG: menu-bar extras stay monochrome, so the glyph is drawn in `labelColor` (resolved at draw time, so it
/// follows light/dark/tinted menu bars) and only the small dot carries color, cut out of the glyph with a clear
/// ring so it reads on any wallpaper.
enum StatusIcon {
    static func image(connected: Bool) -> NSImage {
        let size = NSSize(width: 22, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            guard let glyph = NSImage(systemSymbolName: "signature", accessibilityDescription: nil)?
                .withSymbolConfiguration(config) else { return false }
            let glyphRect = NSRect(x: 0, y: (rect.height - glyph.size.height) / 2,
                                   width: glyph.size.width, height: glyph.size.height)
            glyph.draw(in: glyphRect)
            NSColor.labelColor.set()
            glyphRect.fill(using: .sourceAtop)

            let dot = NSRect(x: rect.width - 8.5, y: 1, width: 7.5, height: 7.5)
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
