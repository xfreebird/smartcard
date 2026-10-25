import SwiftUI
import ServiceManagement
import MoldSignKit

/// docs/10 §4.2 Settings (MAC-09).
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings().tabItem { Label("General", systemImage: "gearshape") }
            BridgeSettings().tabItem { Label("Conexiune browser", systemImage: "globe") }
        }
        .frame(width: 520, height: 360)
    }
}

private struct GeneralSettings: View {
    @Environment(AppModel.self) private var model
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?

    var body: some View {
        Form {
            Toggle("Pornește la autentificare", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        launchError = nil
                    } catch {
                        launchError = error.localizedDescription
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
            if let launchError { Text(launchError).font(.caption).foregroundStyle(Theme.danger) }
            LabeledContent("Format PDF", value: "PAdES-T")
            LabeledContent("Alte fișiere", value: "XAdES-T, detașat")
            LabeledContent("Salvare", value: String(localized: "Lângă original (-semnat), fără suprascriere"))
            Section {
                Button("Șterge PIN-ul salvat", role: .destructive) { model.forgetPIN() }
                    .disabled(!model.hasStoredPIN)
            }
            // TODO(MAC-16): language picker once ru/en String Catalogs exist
        }
        .formStyle(.grouped)
    }
}

private struct BridgeSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Toggle("Răspunde cererilor de semnare din browser", isOn: $model.bridgeEnabled)
            LabeledContent("Adrese", value: "127.0.0.1:18480 · localhost.cts.md:18443")
            if model.bridgeState == .portBusy {
                Text("Porturile sunt folosite de MoldSign Desktop Suite (Java). Închide-l pentru a folosi această aplicație.")
                    .font(.caption).foregroundStyle(Theme.warning)
                // TODO(MAC-08): offer to quit the vendor server
            }
            Section("Site-uri permise") {
                Text(BridgeOriginPolicy.vendorDefault.patterns.prefix(12).joined(separator: "\n") + "\n…")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
