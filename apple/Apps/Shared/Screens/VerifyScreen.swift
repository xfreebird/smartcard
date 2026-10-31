import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

/// "Verifică": choose or drop a signed file → verdict + one section per signature (UX-03/UX-04).
struct VerifyScreen: View {
    @Environment(AppModel.self) private var model
    @State private var importing = false
    @State private var dropTargeted = false

    var body: some View {
        Form {
            Section {
                Button { importing = true } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.verifyFile == nil ? L10n.text(.ui_choose_the_signed_document) : L10n.text(.ui_choose_another_document))
                            Text(L10n.text(.ui_or_drop_it_here_signed_pdf_or_xades_signature_xml)).font(.caption).foregroundStyle(Color.secondary)
                        }
                    } icon: { Image(systemName: "checkmark.seal") }
                }
                .buttonStyle(.borderless)
            }

            if let file = model.verifyFile {
                if let reports = model.verifyReports {
                    Section {
                        if model.demoMode {
                            Label(L10n.text(.demo_simulation_complete), systemImage: "sparkles")
                            Text(L10n.text(.demo_output_notice)).foregroundStyle(.secondary)
                        } else {
                        VerdictBadge(verdict: Verdict(reports))
                            .padding(.vertical, 4)
                        LabeledContent(L10n.text(.ui_document), value: file.lastPathComponent)
                        }
                    }
                    ForEach(Array(reports.enumerated()), id: \.offset) { index, report in
                        SignatureSection(report: report, index: index + 1)
                    }
                } else {
                    Section { ProgressView(L10n.text(.ui_verifying)) }
                }
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) { if model.demoMode { DemoModeBanner() } }
        #endif
        .navigationTitle(L10n.text(.ui_verify))
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 12).strokeBorder(Color.accentColor, lineWidth: 2).padding(4).allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            if let url = urls.first { Task { await model.verify(url) } }
            return !urls.isEmpty
        } isTargeted: { dropTargeted = $0 }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .xml, .item]) { result in
            if case .success(let url) = result { Task { await model.verify(url) } }
        }
    }
}

private struct SignatureSection: View {
    let report: Validator.Report
    let index: Int

    var body: some View {
        Section {
            LabeledContent(L10n.text(.ui_signer), value: report.signer)
            LabeledContent(L10n.text(.ui_signed_at), value: report.signingTime)
            if let tst = report.timestampTime { LabeledContent(L10n.text(.ui_timestamp), value: tst) }
            LabeledContent(L10n.text(.ui_level), value: report.level)
            check(L10n.text(.ui_document_integrity), report.contentIntact)
            check(L10n.text(.ui_cryptographic_signature), report.signatureValid)
            check(L10n.text(.ui_trust_chain_mdqsign_mdtrustca), report.chainTrusted)
            DisclosureGroup(L10n.text(.ui_technical_details)) {
                Text(report.summary).font(.caption.monospaced()).textSelection(.enabled)
            }
        } header: {
            Text(L10n.text(.ui_signature_count, index))
        }
    }

    private func check(_ title: String, _ ok: Bool) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundStyle(ok ? .green : .red)
        }
    }
}

struct ActivityScreen: View {
    @Environment(AppModel.self) private var model
    @State private var confirmClear = false

    var body: some View {
        List {
            ForEach(model.activity) { item in
                ActivityRowView(item: item)
                    .contextMenu {
                        #if os(macOS)
                        if let url = item.fileURL {
                            Button(L10n.text(.ui_show_in_finder)) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                        }
                        #endif
                    }
            }
        }
        .overlay {
            if model.activity.isEmpty {
                ContentUnavailableView(L10n.text(.ui_no_activity_yet), systemImage: "clock",
                                       description: Text(L10n.text(.ui_signed_and_verified_documents_appear_here)))
            }
        }
        .navigationTitle(L10n.text(.ui_activity))
        .onAppear { model.pruneMissingFiles() }      // moved/deleted documents drop out of the list
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) { confirmClear = true } label: { Label(L10n.text(.ui_clear_list), systemImage: "trash") }
                    .disabled(model.activity.isEmpty)
                    .help(L10n.text(.ui_clear_history_documents_remain_on_disk))
            }
        }
        .confirmationDialog(L10n.text(.ui_clear_the_activity_list), isPresented: $confirmClear, titleVisibility: .visible) {
            Button(L10n.text(.ui_clear_list), role: .destructive) { model.clearActivity() }
        } message: {
            Text(L10n.text(.ui_signed_documents_remain_on_disk_only_the_history_is_cleared))
        }
    }
}

/// "Card": the card selector + the selected card's certificate and PIN.
struct CardScreen: View {
    @Environment(AppModel.self) private var model
    @State private var copied = false
    #if os(iOS)
    @State private var settingsPresented = false
    #endif

    var body: some View {
        Form {
            Section {
                CardSelector(size: cardSize)
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
                                .buttonStyle(.borderless)
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
        .safeAreaInset(edge: .top, spacing: 0) { if model.demoMode { DemoModeBanner() } }
        #endif
        .navigationTitle(L10n.text(.ui_card))
        #if os(iOS)
        .sheet(isPresented: $settingsPresented) { MobileSettingsView().environment(model).appPreferences() }
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
        return .phone
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
