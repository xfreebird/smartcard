import SwiftUI

/// Design tokens from docs/10-design-system.md §2.
enum Theme {
    static let brand = Color(light: 0x2350D8, dark: 0x7C9BFF)
    static let brandSoft = Color(light: 0xE8EEFF, dark: 0x1C2547)
    static let accent = Color(light: 0xF5B700, dark: 0xFFCD3C)
    static let success = Color(light: 0x15803D, dark: 0x4ADE80)
    static let warning = Color(light: 0xB45309, dark: 0xFBBF24)
    static let danger = Color(light: 0xC62828, dark: 0xF87171)
    static let surfaceRaised = Color(light: 0xFFFFFF, dark: 0x1E1F24)
    /// Text on `brand` fills: white fails contrast on the light dark-mode brand (2.6:1), so dark mode uses navy (7:1).
    static let onBrand = Color(light: 0xFFFFFF, dark: 0x0B1230)
    static let successSoft = Color(light: 0xEDF7F0, dark: 0x12291B)
    static let warningSoft = Color(light: 0xFEF5E7, dark: 0x2E2410)
    static let dangerSoft = Color(light: 0xFDECEC, dark: 0x331616)

    enum Radius {
        static let control: CGFloat = 10
        static let card: CGFloat = 14
        static let sheet: CGFloat = 18
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    static let popoverWidth: CGFloat = 360
}

extension Color {
    /// Fixed sRGB color (illustrations that look the same in light and dark).
    init(rgb: UInt32) {
        self.init(.sRGB, red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255)
    }

    /// Light/dark pair resolved by the system appearance.
    init(light: UInt32, dark: UInt32) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(rgb: dark) : NSColor(rgb: light)
        })
        #else
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
        #endif
    }
}

#if os(macOS)
private extension NSColor {
    convenience init(rgb: UInt32) {
        self.init(srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}
#else
private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}
#endif

/// Raised card container used by StatusCard, SignatureCard, file lists.
struct CardSurface<Content: View>: View {
    var padding: CGFloat = Theme.Space.l
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(.primary.opacity(0.08)))
    }
}
