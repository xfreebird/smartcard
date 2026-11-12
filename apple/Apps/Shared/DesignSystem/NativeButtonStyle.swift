import SwiftUI

/// System-rendered actions: Liquid Glass on supported iOS versions, native legacy styles elsewhere.
/// Keep this on standalone actions. Menus, alerts, toolbars and interactive rows own their chrome.
enum NativeButtonStyle: ViewModifier {
    case standard, prominent, borderless, automatic

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26, *) {
            if case .prominent = self {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            legacy(content)
        }
        #else
        legacy(content)
        #endif
    }

    @ViewBuilder
    private func legacy(_ content: Content) -> some View {
        switch self {
        case .standard: content.buttonStyle(.bordered)
        case .prominent: content.buttonStyle(.borderedProminent)
        case .borderless: content.buttonStyle(.borderless)
        case .automatic: content.buttonStyle(.automatic)
        }
    }
}

extension View {
    func nativeButtonStyle(_ style: NativeButtonStyle = .standard) -> some View {
        modifier(style)
    }

    /// Glass supplies its own padding; older borderless controls need an explicit touch target.
    @ViewBuilder
    func nativeButtonIconFrame(legacySize: CGFloat = 44) -> some View {
        #if os(iOS)
        if #available(iOS 26, *) {
            frame(width: 20, height: 20)
        } else {
            frame(width: legacySize, height: legacySize).contentShape(Rectangle())
        }
        #else
        frame(width: legacySize, height: legacySize).contentShape(Rectangle())
        #endif
    }
}
