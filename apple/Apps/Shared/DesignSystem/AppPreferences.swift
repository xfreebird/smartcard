import SwiftUI
#if os(macOS)
import AppKit
#endif

/// One preference boundary for windows, sheets and previews.
struct AppPreferences: ViewModifier {
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"
    @AppStorage("appTheme", store: AppPreferencesStore.defaults) private var theme = "system"

    func body(content: Content) -> some View {
        content
            // Localized strings are resolved by key in L10n, rather than as SwiftUI
            // LocalizedStringKeys. Recreate this presentation when its language changes.
            .id(language)
            .environment(\.locale, language == "system" ? .autoupdatingCurrent : Locale(identifier: language))
            .preferredColorScheme(theme == "light" ? .light : theme == "dark" ? .dark : nil)
            #if os(macOS)
            .onAppear { applyNativeAppearance(theme) }
            .onChange(of: theme) { _, value in applyNativeAppearance(value) }
            #endif
    }

    #if os(macOS)
    private func applyNativeAppearance(_ value: String) {
        NSApp.appearance = value == "light" ? NSAppearance(named: .aqua)
            : value == "dark" ? NSAppearance(named: .darkAqua) : nil
    }
    #endif
}

extension View {
    func appPreferences() -> some View { modifier(AppPreferences()) }
}
