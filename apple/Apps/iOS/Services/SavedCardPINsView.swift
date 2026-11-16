import SwiftUI

/// Management uses account metadata only; viewing or deleting an entry never retrieves a PIN.
struct SavedCardPINsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Form {
            Section {
                if model.savedPINAccounts.isEmpty {
                    Text(L10n.text(.ui_no_saved_pins)).foregroundStyle(.secondary)
                }
                ForEach(model.savedPINAccounts, id: \.self) { account in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.knownSigningCertificates.first { $0.sha1Hex == account }?.holder
                                 ?? L10n.text(.ui_identity_card))
                            Text(String(account.suffix(8))).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) { model.forgetPIN(certID: account) } label: {
                            Label(L10n.text(.ui_delete), systemImage: "trash")
                        }
                            .disabled(!model.canChangeSigningMethod)
                            .accessibilityIdentifier("savedPIN.delete.\(account)")
                    }
                }
            } footer: {
                Text(L10n.text(.pin_shared_channels))
            }
        }
        .navigationTitle(L10n.text(.ui_saved_pins))
    }
}
