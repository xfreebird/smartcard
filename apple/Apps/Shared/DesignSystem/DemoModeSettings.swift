import SwiftUI

/// Enabling demo always requires a user choice; persisting a setting never silently authorizes it.
struct DemoModeSettings: View {
    @Environment(AppModel.self) private var model
    @State private var confirming = false
    @State private var switchError = false
    var body: some View {
        Section {
            Toggle(L10n.text(.demo_settings_title), isOn: Binding(
                get: { model.demoMode },
                set: { enabled in
                    if enabled { confirming = true } else { switchError = !model.setDemoMode(false) }
                }
            ))
            .disabled(!model.canChangeDemoMode)
            .accessibilityIdentifier("settings.demoMode")
            .confirmationDialog(L10n.text(.demo_enable_title), isPresented: $confirming, titleVisibility: .visible) {
            Button(L10n.text(.demo_enable_action)) { switchError = !model.setDemoMode(true) }
            Button(L10n.text(.ui_cancel), role: .cancel) {}
        } message: { Text(L10n.text(.demo_settings_description)) }
            .alert(L10n.text(.ui_demo_mode), isPresented: $switchError) {
            Button(L10n.text(.ui_done)) {}
        } message: { Text(L10n.text(.demo_switch_unavailable)) }

            Text(L10n.text(.demo_settings_description)).font(.caption).foregroundStyle(.secondary)
        }

    }
}

struct DemoModeBanner: View {
    var body: some View {
        Label(L10n.text(.demo_banner), systemImage: "sparkles")
            .font(.callout.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.orange.opacity(0.14))
            .accessibilityIdentifier("demo.banner")
    }
}
