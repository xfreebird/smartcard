import SwiftUI

struct MobileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"
    @AppStorage("appTheme", store: AppPreferencesStore.defaults) private var theme = "system"
    private var languageChoice: Binding<String> {
        Binding(get: { language }, set: { value in
            if value == "system" { AppPreferencesStore.defaults.removeObject(forKey: "AppleLanguages") }
            language = value
        })
    }
    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text(.ui_appearance_and_language)) {
                    Picker(L10n.text(.ui_language), selection: languageChoice) {
                        Text(L10n.text(.ui_system)).tag("system")
                        Text(verbatim: "Română").tag("ro")
                        Text(verbatim: "English").tag("en")
                        Text(verbatim: "Русский").tag("ru")
                    }
                    Picker(L10n.text(.ui_theme), selection: $theme) {
                        Text(L10n.text(.ui_system)).tag("system")
                        Text(L10n.text(.ui_light)).tag("light")
                        Text(L10n.text(.ui_dark)).tag("dark")
                    }
                }
                DemoModeSettings()
                Section { NavigationLink(L10n.text(.about_app_title)) { AboutContent() } }
            }
            .navigationTitle(L10n.text(.ui_settings))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text(.ui_done)) { dismiss() } } }
        }
    }
}
