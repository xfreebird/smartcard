import SwiftUI

/// Shared content for the About window and Settings, so they cannot drift apart.
struct AboutContent: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func legalURL(_ page: String) -> URL {
        let preference = AppPreferencesStore.defaults.string(forKey: "appLanguage") ?? "system"
        let language = String((preference == "system" ? (Locale.preferredLanguages.first ?? "ro") : preference).prefix(2))
        let prefix = ["ro", "ru"].contains(language) ? "/\(language)" : ""
        return URL(string: "https://esemnbun.md\(prefix)/\(page)/")!
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                #if os(macOS)
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().interpolation(.high).frame(width: 80, height: 80)
                #else
                Image("AboutIcon").resizable().interpolation(.high)
                    .frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 18))
                #endif
                Text(verbatim: "eSemnBun").font(.title2.bold())
                Text(version).foregroundStyle(.secondary)
                Text(verbatim: "Nicolae Ghimbovschi")
                Link("esemnbun.md", destination: URL(string: "https://esemnbun.md")!)
                Divider().padding(.vertical, 8)
                Text(L10n.text(.about_legal_title)).font(.headline)
                Text(L10n.text(.about_disclaimer_body))
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Link(L10n.text(.about_terms), destination: legalURL("terms"))
                Link(L10n.text(.about_privacy), destination: legalURL("privacy"))
                Link(L10n.text(.about_disclaimer), destination: legalURL("terms"))
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .navigationTitle(L10n.text(.about_app_title))
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 340)
        #endif
    }
}
