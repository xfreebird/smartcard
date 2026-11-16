import SwiftUI

struct MobileSettingsView: View {
    @State private var presentedSetting: MobileSettingsDestination?
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"
    @AppStorage("browserStampsEnabled", store: AppPreferencesStore.defaults) private var browserStamps = false
    @AppStorage("appTheme", store: AppPreferencesStore.defaults) private var theme = "system"
    private var languageChoice: Binding<String> {
        Binding(get: { language }, set: { value in
            if value == "system" { AppPreferencesStore.defaults.removeObject(forKey: "AppleLanguages") }
            language = value
        })
    }
    var body: some View {
            Form {
                DemoModeSettings()
                Section(L10n.text(.settings_signing)) {
                    setting(.cards, title: .settings_card_reader, icon: "person.text.rectangle", id: "settings.card")
                    setting(.pins, title: .ui_saved_pins, icon: "key", id: "card.savedPINs")
                    setting(.help, title: .nfc_how_it_works, icon: "questionmark.circle", id: "settings.help")
                }
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
                Section(L10n.text(.ui_browser)) {
                    Toggle(L10n.text(.stamp_browser), isOn: $browserStamps)
                    Text(L10n.text(.stamp_batch_hint)).font(.caption)
                }
                Section(L10n.text(.ui_documents)) { DocumentDiscoverySettings() }
                Section { setting(.about, title: .about_app_title, icon: "info.circle", id: "settings.about") }
            }
            .navigationTitle(L10n.text(.ui_settings))
            .accessibilityIdentifier("settings.screen")
            .sheet(item: $presentedSetting) { MobileSettingsSheet(destination: $0) }
    }

    private func setting(_ destination: MobileSettingsDestination, title: L10n.Key, icon: String, id: String) -> some View {
        Button { presentedSetting = destination } label: {
            Label { Text(L10n.text(title)).foregroundStyle(.primary) }
                icon: { Image(systemName: icon).foregroundStyle(Theme.brand) }
                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }.accessibilityIdentifier(id)
    }
}

enum MobileSettingsDestination: String, Identifiable {
    case cards, details, pins, help, about
    var id: String { rawValue }
}

/// A focused task returns to its caller without adding a new Settings navigation level.
struct MobileSettingsSheet: View {
    let destination: MobileSettingsDestination
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch destination {
                case .cards: CardScreen()
                case .details: CardScreen(detailsOnly: true)
                case .pins: SavedCardPINsView()
                case .help: SigningHelpPage()
                case .about: AboutContent()
                }
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button(L10n.text(.ui_done)) { dismiss() }
                    .accessibilityIdentifier("settings.sheet.done")
            } }
        }
        .presentationDragIndicator(.visible)
    }
}
