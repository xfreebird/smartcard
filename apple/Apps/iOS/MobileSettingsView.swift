import SwiftUI

struct MobileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"
    @AppStorage("appTheme", store: AppPreferencesStore.defaults) private var theme = "system"
    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text(.ui_appearance_and_language)) {
                    Picker(L10n.text(.ui_language), selection: $language) {
                        Text(L10n.text(.ui_system)).tag("system")
                        Text(verbatim: "Română").tag("ro")
                        Text(verbatim: "English").tag("en")
                        Text(verbatim: "Русский").tag("ru")
                    }
                    .onChange(of: language) { _, value in
                        if value == "system" { AppPreferencesStore.defaults.removeObject(forKey: "AppleLanguages") }
                        else { AppPreferencesStore.defaults.set([value], forKey: "AppleLanguages") }
                    }
                    Picker(L10n.text(.ui_theme), selection: $theme) {
                        Text(L10n.text(.ui_system)).tag("system")
                        Text(L10n.text(.ui_light)).tag("light")
                        Text(L10n.text(.ui_dark)).tag("dark")
                    }
                }
                DemoModeSettings()
                Section(L10n.text(.about_app_title)) {
                    LabeledContent(L10n.text(.about_developer), value: "Nicolae Ghimbovschi")
                    Link("esemnbun.md", destination: URL(string: "https://esemnbun.md")!)
                }
            }
            .navigationTitle(L10n.text(.ui_settings))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text(.ui_done)) { dismiss() } } }
        }
    }
}
