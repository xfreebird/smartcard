import SwiftUI

/// One preference boundary for windows, sheets and previews.
struct AppPreferences: ViewModifier {
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"
    @AppStorage("appTheme", store: AppPreferencesStore.defaults) private var theme = "system"

    func body(content: Content) -> some View {
        content
            .environment(\.locale, language == "system" ? .autoupdatingCurrent : Locale(identifier: language))
            .preferredColorScheme(theme == "light" ? .light : theme == "dark" ? .dark : nil)
    }
}

extension View {
    func appPreferences() -> some View { modifier(AppPreferences()) }
}
