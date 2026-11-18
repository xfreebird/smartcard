import SwiftUI

/// Manage the same certificate identity across NFC and USB, including disconnected cards.
struct SavedCardPINsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let accounts = model.savedPINAccounts
        let otherCards = model.knownSigningCertificates.filter { !accounts.contains($0.sha1Hex) }
        Form {
            Section {
                if accounts.isEmpty {
                    Text(L10n.text(.ui_no_saved_pins)).foregroundStyle(.secondary)
                }
                ForEach(accounts, id: \.self) { account in
                    accountRow(account, holder: model.knownSigningCertificates.first { $0.sha1Hex == account }?.holder)
                }
                #if os(macOS)
                if !accounts.isEmpty {
                    Button(role: .destructive) {
                        for account in accounts { model.forgetCard(certID: account) }
                    } label: { Label(L10n.text(.ui_delete_all_pins), systemImage: "trash") }
                }
                #endif
            } header: {
                Text(L10n.text(.ui_saved_pins))
            } footer: { Text(L10n.text(.card_forget_hint)) }
            if !otherCards.isEmpty {
                Section(L10n.text(.card_without_pin)) {
                    ForEach(otherCards, id: \.sha1Hex) { card in
                        accountRow(card.sha1Hex, holder: card.holder)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .disabled(!model.canChangeSigningMethod)
        .navigationTitle(L10n.text(.card_saved_identities_title))
    }

    private func accountRow(_ account: String, holder: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(holder ?? L10n.text(.ui_identity_card))
                Text(String(account.suffix(8))).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            Button(role: .destructive) { model.forgetCard(certID: account) } label: {
                Label(L10n.text(.card_forget), systemImage: "trash")
            }
            .accessibilityIdentifier("savedPIN.delete.\(account)")
        }
    }
}
