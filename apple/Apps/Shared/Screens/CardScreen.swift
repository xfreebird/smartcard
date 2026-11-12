import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

/// "Card": the card selector + the selected card's certificate and PIN.
struct CardScreen: View {
    @Environment(AppModel.self) private var model
    @State private var copied = false
    #if os(iOS)
    @State private var settingsPresented = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    var body: some View {
        Form {
            Section {
                Group {
                    #if os(iOS)
                    if verticalSizeClass == .compact {
                        DisclosureGroup(L10n.text(.ui_card)) { CardSelector(size: .compact) }
                    } else { CardSelector(size: cardSize) }
                    #else
                    CardSelector(size: cardSize)
                    #endif
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            } footer: {
                if model.cards.count > 1 {
                    #if os(macOS)
                    Text(L10n.text(.ui_swipe_horizontally_or_use_the_arrows_to_choose_a_card_right_click_to_read_it_again))
                    #else
                    Text(L10n.text(.ui_swipe_horizontally_or_use_the_arrows_to_choose_a_card_touch_and_hold_to_read_it_again))
                    #endif
                }
            }

            if let cert = model.certificate {
                Section(L10n.text(.ui_signing_certificate)) {
                    LabeledContent(L10n.text(.ui_holder), value: cert.holder)
                    LabeledContent(L10n.text(.ui_issuer), value: cert.issuerName)
                    if let until = cert.notAfter {
                        LabeledContent(L10n.text(.ui_valid_until), value: until.formatted(date: .long, time: .omitted))
                    }
                    LabeledContent(L10n.text(.ui_serial_number), value: cert.serialDecimal)
                    LabeledContent(L10n.text(.ui_sha_1)) {
                        HStack {
                            Text(cert.sha1Hex).font(.caption.monospaced()).textSelection(.enabled)
                            Button {
                                copy(cert.sha1Hex)
                            } label: { Image(systemName: copied ? "checkmark" : "doc.on.doc") }
                                .nativeButtonStyle(.borderless)
                                .buttonBorderShape(.circle)
                                .accessibilityLabel(L10n.text(.ui_copy_sha_1))
                        }
                    }
                    if let reader = model.selectedCard?.reader { LabeledContent(L10n.text(.ui_reader), value: reader) }
                }
                Section {
                    Label(model.hasStoredPIN ? L10n.text(.ui_pin_is_saved) : L10n.text(.ui_pin_is_not_saved),
                          systemImage: model.hasStoredPIN ? "key.fill" : "key")
                    if model.hasStoredPIN {
                        Button(L10n.text(.ui_delete_the_saved_pin), role: .destructive) { model.forgetPIN() }
                    }
                } header: {
                    Text(L10n.text(.ui_pin))
                } footer: {
                    Text(L10n.text(.ui_the_saved_pin_is_unlocked_using_touch_id_face_id_or_the_device_password_and_is_linked_to))
                }
            }

            Section(L10n.text(.ui_card_problems)) {
                Label(L10n.text(.ui_if_signing_fails_repeatedly_remove_and_reinsert_the_card), systemImage: "arrow.triangle.2.circlepath")
                Label(L10n.text(.ui_the_pin_is_not_retried_automatically_after_3_incorrect_attempts_the_card_is_blocked), systemImage: "lock.shield")
                Label(L10n.text(.ui_the_pin_can_be_unblocked_at_cev), systemImage: "building.columns")
            }
            .font(.callout)
        }
        .formStyle(.grouped)
        #if os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) { if model.showsDemoNotice { DemoModeBanner() } }
        #endif
        .navigationTitle(L10n.text(.ui_card))
        #if os(iOS)
        .sheet(isPresented: $settingsPresented) { MobileSettingsView().environment(model).appPreferences() }
        .onAppear {
            #if DEBUG
            if model.isScreenshotCapture, ProcessInfo.processInfo.environment["MSIGN_CAPTURE_SHEET"] == "settings" {
                settingsPresented = true
            }
            #endif
        }
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                Button { settingsPresented = true } label: { Label(L10n.text(.ui_settings), systemImage: "gearshape") }
                    .accessibilityIdentifier("card.settings")
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button { model.rereadCards() } label: { Label(L10n.text(.ui_read_the_card_again), systemImage: "arrow.clockwise") }
                    .disabled(model.cards.isEmpty)
                    .help(L10n.text(.ui_read_the_cards_again_after_removing_or_changing_a_card))
            }
        }
    }

    private var cardSize: CardSelector.Size {
        #if os(macOS)
        return .large
        #else
        return verticalSizeClass == .compact ? .compact : .phone
        #endif
    }

    private func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
        copied = true
    }
}
