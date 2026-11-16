import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

/// "Card": the card selector + the selected card's certificate and PIN.
struct CardScreen: View {
    var detailsOnly = false
    @Environment(AppModel.self) private var model
    @State private var copied = false
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var presentedSetting: MobileSettingsDestination?
    #endif

    var body: some View {
        Group {
            #if os(iOS)
            if detailsOnly {
                Form { expandedDetails }
            } else {
            ScrollView {
                VStack(spacing: 28) {
                    SigningCardChoice(compact: true, inlineReaderCards: true)
                    VStack(spacing: 0) {
                        if model.signingCertificate != nil {
                            Button { presentedSetting = .details } label: {
                                mobileRow(.card_details_title, icon: "person.text.rectangle")
                            }.accessibilityIdentifier("card.details")
                        }
                    }.background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 22)).buttonStyle(.plain)
                }.frame(maxWidth: 560).padding(24).frame(maxWidth: .infinity)
            }.background(Color(uiColor: .systemGroupedBackground))
            }
            #else
            cardForm
            #endif
        }
        #if os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) { if model.showsDemoNotice { DemoModeBanner() } }
        .sheet(item: $presentedSetting) { MobileSettingsSheet(destination: $0) }
        #endif
        #if os(macOS)
        .navigationTitle(L10n.text(.ui_card))
        #else
        .navigationTitle(L10n.text(detailsOnly ? .card_details_title : .settings_card_reader))
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if showsReaderCard {
                ToolbarItem(placement: .primaryAction) {
                    Button { model.rereadCards() } label: { Label(L10n.text(.ui_read_the_card_again), systemImage: "arrow.clockwise") }
                        .disabled(model.cards.isEmpty || !model.canChangeSigningMethod)
                        .help(L10n.text(.ui_read_the_cards_again_after_removing_or_changing_a_card))
                }
            }
        }
    }

    #if os(iOS)
    private func mobileRow(_ title: L10n.Key, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(Theme.brand).frame(width: 26)
            Text(L10n.text(title)).foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }.padding(18).frame(minHeight: 60).contentShape(Rectangle())
    }
    #endif

    private var cardForm: some View {
        Form {
            cardSection
            detailSections
        }
        .formStyle(.grouped)
    }

    private var cardSection: some View {
        Section {
            cardChoice
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
        } footer: {
            cardSelectionHint
        }
    }

    @ViewBuilder
    private var cardChoice: some View {
        #if os(iOS)
        SigningCardChoice(size: cardSize)
        #else
        CardSelector(size: cardSize)
        #endif
    }

    @ViewBuilder
    private var cardSelectionHint: some View {
        if model.cards.count > 1 && showsReaderCard {
            #if os(macOS)
            Text(L10n.text(.ui_swipe_horizontally_or_use_the_arrows_to_choose_a_card_right_click_to_read_it_again))
            #else
            Text(L10n.text(.ui_swipe_horizontally_or_use_the_arrows_to_choose_a_card_touch_and_hold_to_read_it_again))
            #endif
        }
    }

    private var showsReaderCard: Bool {
        #if os(iOS)
        model.signingMethod == .reader
        #else
        true
        #endif
    }

    @ViewBuilder
    private var detailSections: some View {
        #if os(iOS)
        Section {
            if model.signingCertificate != nil {
                Button { presentedSetting = .details } label: {
                    Label(L10n.text(.card_details_title), systemImage: "person.text.rectangle")
                }.accessibilityIdentifier("card.details")
            }
            savedPINsLink
        }
        Section {
            DisclosureGroup(L10n.text(.card_help_title)) {
                Text(L10n.text(.ui_the_pin_is_not_retried_automatically_after_3_incorrect_attempts_the_card_is_blocked))
                Text(L10n.text(.ui_the_pin_can_be_unblocked_at_cev))
            }
        }
        #else
        expandedDetails
        #endif
    }

    @ViewBuilder
    private var expandedDetails: some View {
        if let cert = model.signingCertificate {
            pinSection(for: cert)
            #if os(macOS)
            Section {
                SettingsDisclosure(title: .ui_signing_certificate) { certificateDetails(cert) }
                    .accessibilityIdentifier("card.certificate.details")
            }
            #else
            Section(L10n.text(.ui_signing_certificate)) { certificateDetails(cert) }
            #endif
        }

        #if os(iOS)
        if model.signingCertificate == nil {
            Section { savedPINsLink }
        }
        Section(L10n.text(.ui_card_problems)) { cardProblems }.font(.callout)
        #else
        Section {
            SettingsDisclosure(title: .ui_card_problems) {
                VStack(alignment: .leading, spacing: 12) { cardProblems }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    .padding(.vertical, 8)
            }
                .accessibilityIdentifier("card.troubleshooting")
        }.font(.callout)
        #endif
    }

    @ViewBuilder
    private func certificateDetails(_ cert: SigningService.CertificateSummary) -> some View {
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
        if showsReaderCard, let reader = model.selectedCard?.reader {
            LabeledContent(L10n.text(.ui_reader), value: reader)
        }
    }

    @ViewBuilder
    private var cardProblems: some View {
        Label(L10n.text(.ui_if_signing_fails_repeatedly_remove_and_reinsert_the_card), systemImage: "arrow.triangle.2.circlepath")
        Label(L10n.text(.ui_the_pin_is_not_retried_automatically_after_3_incorrect_attempts_the_card_is_blocked), systemImage: "lock.shield")
        Label(L10n.text(.ui_the_pin_can_be_unblocked_at_cev), systemImage: "building.columns")
    }

    private func pinSection(for cert: SigningService.CertificateSummary) -> some View {
        Section {
            Label(model.hasStoredPIN(certID: cert.sha1Hex) ? L10n.text(.ui_pin_is_saved) : L10n.text(.ui_pin_is_not_saved),
                  systemImage: model.hasStoredPIN(certID: cert.sha1Hex) ? "key.fill" : "key")
                .accessibilityIdentifier("card.pin.status")
            if model.hasStoredPIN(certID: cert.sha1Hex) {
                Button(role: .destructive) { model.forgetPIN(certID: cert.sha1Hex) } label: {
                    Label(L10n.text(.ui_delete_the_saved_pin), systemImage: "trash")
                }
                    .disabled(!model.canChangeSigningMethod)
                    .accessibilityIdentifier("card.pin.delete")
            }
            #if os(iOS)
            savedPINsLink
            #endif
        } header: {
            Text(L10n.text(.ui_pin))
        } footer: {
            #if os(iOS)
            Text(L10n.text(.pin_shared_channels))
            #else
            Text(L10n.text(.ui_the_saved_pin_is_unlocked_using_touch_id_face_id_or_the_device_password_and_is_linked_to))
            #endif
        }
    }

    #if os(iOS)
    private var savedPINsLink: some View {
        Button { presentedSetting = .pins } label: {
            Label(L10n.text(.ui_saved_pins), systemImage: "key")
        }
        .accessibilityIdentifier("card.savedPINs")
    }
    #endif

    private var cardSize: CardSelector.Size {
        #if os(macOS)
        return .compact
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
