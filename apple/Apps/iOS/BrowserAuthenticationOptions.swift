import SwiftUI

/// The browser button and Settings edit the same saved authentication preference.
struct BrowserAuthenticationOptions: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let readCard: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(L10n.text(model.bridgeState == .running ? .ui_browser_connection_on : .ui_browser_connection_off),
                          systemImage: model.bridgeState == .running ? "checkmark.circle" : "exclamationmark.circle")
                        .foregroundStyle(model.bridgeState == .running ? Theme.success : Theme.warning)
                }
                Section {
                    Picker(L10n.text(.browser_authentication_method), selection: Binding(
                        get: { model.browserNFC.enabled }, set: { model.browserNFC.enabled = $0 }
                    )) {
                        Text(L10n.text(.browser_nfc_method)).tag(true).disabled(!model.nfcAvailable)
                        Text(L10n.text(.browser_nfc_reader)).tag(false)
                    }.pickerStyle(.inline)
                }
                if model.browserNFC.enabled {
                    Section(L10n.text(.ui_card)) {
                        if let selected = model.browserNFC.certificate {
                            Text(selected.holder)
                            Text(L10n.text(.browser_nfc_ready)).font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(model.knownSigningCertificates, id: \.sha1Hex) { card in
                            Button {
                                model.browserNFC.certificate = card
                            } label: {
                                HStack {
                                    Text(card.holder)
                                    Spacer()
                                    if model.browserNFC.certificate?.sha1Hex == card.sha1Hex {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        Button(L10n.text(.browser_nfc_read), action: readCard)
                    }
                    if let error = model.browserNFC.error {
                        Section { Text(error).foregroundStyle(.red) }
                    }
                }
            }
            .disabled(!model.canChangeSigningMethod)
            .navigationTitle(L10n.text(.browser_authentication_method))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text(.ui_done)) { dismiss() }
                }
            }
        }
    }
}
