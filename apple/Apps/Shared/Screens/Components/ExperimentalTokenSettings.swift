import SwiftUI

/// Phase TOK: USB signing tokens, experimental and off by default. Today it only recognizes a token
/// (by ATR) and names it; signing with tokens comes with the drivers (PLAN.md TOK-06…).
struct ExperimentalTokenSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            Toggle(L10n.text(.token_experimental_title), isOn: $model.experimentalTokens)
                .accessibilityIdentifier("settings.experimentalTokens")
        } footer: {
            Text(L10n.text(.token_experimental_detail)).font(.caption).foregroundStyle(.secondary)
        }
    }
}
