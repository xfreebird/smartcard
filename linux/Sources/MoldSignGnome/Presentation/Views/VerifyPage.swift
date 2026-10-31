import CAdwaita
import Foundation
import MoldSignKit

/// docs/10 §4.2 "Verifică": drop a signed file → VerdictBadge + one group per signature (LNX-09).
final class VerifyPage {
    let root: Widget
    private let controller: AppController
    private let window: () -> UnsafeMutablePointer<GtkWindow>?
    private let stack: OpaquePointer          // GtkStack: empty / checking / result
    private let checkingStatus: Widget
    private let verdict = StatusHeader(icon: "security-high-symbolic", size: 80)   // VerdictBadge
    private let reportsBox: Widget
    private var renderedKey = ""

    init(controller: AppController, window: @escaping () -> UnsafeMutablePointer<GtkWindow>?) {
        self.controller = controller
        self.window = window

        // Empty state
        let choose = button(L10n.text(.ui_choose_file), classes: ["pill", "suggested-action"]) {}
        gtk_widget_set_halign(choose, GTK_ALIGN_CENTER)
        let empty = adw_status_page_new()!
        adw_status_page_set_icon_name(empty.opaque, "security-high-symbolic")
        adw_status_page_set_title(empty.opaque, L10n.text(.ui_verify_signatures))
        adw_status_page_set_description(empty.opaque, L10n.text(.ui_drop_a_signed_pdf_or_xades_signature_xml_here_verification_runs_on_this_computer))
        adw_status_page_set_child(empty.opaque, choose)
        addClasses(empty, ["dropzone"])   // the whole empty state is the drop zone
        margins(empty, 24)

        // Checking
        let spinner = gtk_spinner_new()!
        gtk_spinner_start(spinner.opaque)
        gtk_widget_set_size_request(spinner, 32, 32)
        checkingStatus = adw_status_page_new()!
        adw_status_page_set_title(checkingStatus.opaque, L10n.text(.ui_verifying))
        adw_status_page_set_child(checkingStatus.opaque, spinner)

        // Result
        reportsBox = vbox(spacing: 18)
        let again = button(L10n.text(.ui_verify_another_file), classes: ["pill"]) {}
        gtk_widget_set_halign(again, GTK_ALIGN_CENTER)
        let resultContent = vbox(spacing: 18, [verdict.root, reportsBox, again])
        gtk_widget_set_margin_bottom(resultContent, 24)
        gtk_widget_set_margin_start(resultContent, 24)
        gtk_widget_set_margin_end(resultContent, 24)

        stack = OpaquePointer(gtk_stack_new()!)
        gtk_stack_set_transition_type(stack, GTK_STACK_TRANSITION_TYPE_CROSSFADE)
        gtk_stack_add_named(stack, empty, "empty")
        gtk_stack_add_named(stack, checkingStatus, "checking")
        gtk_stack_add_named(stack, scrolledPage(resultContent), "result")

        root = vbox(spacing: 0, classes: ["drop-page"], [stack.widget])
        gtk_widget_set_vexpand(stack.widget, 1)

        onSignal(choose, "clicked") { [weak self] in self?.pickFile() }
        onSignal(again, "clicked") { [weak self] in self?.pickFile() }
        addFileDropTarget(root) { paths in
            if let first = paths.first { controller.verify(path: first) }
        }
        controller.observe { [weak self] in self?.render() }
    }

    /// "Alege fișierul" / Ctrl+O on this page.
    func pickFile() {
        chooseFiles(parent: window(), title: L10n.text(.ui_choose_the_signed_document), multiple: false,
                    filters: [(L10n.text(.linux_signed_documents_filter), ["pdf", "xml"]), (L10n.text(.ui_all_files), ["*"])]) { [weak self] paths in
            if let first = paths.first { self?.controller.verify(path: first) }
        }
    }

    private func render() {
        guard let file = controller.verifyFile else {
            gtk_stack_set_visible_child_name(stack, "empty")
            renderedKey = ""
            return
        }
        guard let reports = controller.verifyReports else {
            adw_status_page_set_description(checkingStatus.opaque, escapeMarkup(file.lastPathComponent))
            gtk_stack_set_visible_child_name(stack, "checking")
            renderedKey = ""
            return
        }
        let key = file.path + "\(reports.count)"
        guard key != renderedKey else { return }
        renderedKey = key

        let result = Verdict(reports)
        verdict.set(icon: result.icon, title: reports.isEmpty ? L10n.text(.ui_no_signature_found) : result.title,
                    body: file.lastPathComponent + "\n" + (reports.isEmpty ?
                        L10n.text(.ui_the_document_contains_no_recognized_signature) : result.subtitle))
        setClass(verdict.icon, "dim-label", false)
        for name in ["success", "warning", "error"] {
            setClass(verdict.icon, name, name == result.styleClass)
            setClass(verdict.title, name, name == result.styleClass)
        }

        clearBox(reportsBox)
        for (index, report) in reports.enumerated() {
            append(reportsBox, signatureGroup(report, index: index + 1, file: file))
        }
        gtk_stack_set_visible_child_name(stack, "result")
    }

    /// SignatureCard: signer, times, level, three checks, technical details.
    private func signatureGroup(_ report: SignatureReport, index: Int, file: URL) -> Widget {
        let group = preferencesGroup(title: report.signer, description: localized(.ui_signature_value_value, String(index), report.kind))
        let list = boxedList()
        gtk_list_box_append(list.opaque, actionRow(title: L10n.text(.ui_signed_at), subtitle: report.signingTime, icon: "document-edit-symbolic"))
        gtk_list_box_append(list.opaque, actionRow(title: L10n.text(.ui_timestamp), subtitle: report.timestampTime ?? L10n.text(.ui_no_timestamp),
                                                   icon: "document-open-recent-symbolic"))
        gtk_list_box_append(list.opaque, actionRow(title: L10n.text(.ui_level), subtitle: report.level, icon: "security-high-symbolic"))
        gtk_list_box_append(list.opaque, check(L10n.text(.linux_integrity), ok: report.contentIntact,
                                               okText: L10n.text(.ui_the_document_has_not_been_modified_since_signing),
                                               badText: L10n.text(.ui_the_content_differs_from_what_was_signed)))
        gtk_list_box_append(list.opaque, check(L10n.text(.ui_signature), ok: report.signatureValid,
                                               okText: L10n.text(.ui_the_rsa_signature_matches_the_certificate),
                                               badText: L10n.text(.ui_the_signature_does_not_match)))
        gtk_list_box_append(list.opaque, check(L10n.text(.ui_trust_chain), ok: report.chainTrusted,
                                               okText: L10n.text(.ui_issued_by_mdqsign_anchored_in_mdtrustca),
                                               badText: L10n.text(.ui_unknown_or_incomplete_chain), warnOnly: true))

        let details = adw_expander_row_new()!
        adw_preferences_row_set_title(details.cast(), L10n.text(.ui_technical_details))
        let detailRows: [(String, String)] = [
            (L10n.text(.linux_format), report.kind),
            (L10n.text(.linux_identifier), report.name),
            (L10n.text(.linux_summary), report.summary),
        ]
        for (title, value) in detailRows {
            let row = actionRow(title: title, subtitle: value, subtitleSelectable: true)
            addClasses(row, ["property"])
            adw_expander_row_add_row(details.cast(), row)
        }
        if file.pathExtension.lowercased() == "xml" && !report.contentIntact {
            // TODO(LNX-09): inline picker row for the signed file(s) of a detached signature (docs/10 §4.2).
            adw_expander_row_add_row(details.cast(), actionRow(
                title: L10n.text(.ui_detached_signature),
                subtitle: L10n.text(.ui_signed_files_must_be_in_the_same_folder_as_the_xml_signature)))
        }
        gtk_list_box_append(list.opaque, details)
        groupAdd(group, list)
        return group
    }

    private func check(_ title: String, ok: Bool, okText: String, badText: String, warnOnly: Bool = false) -> Widget {
        let icon = image(ok ? "object-select-symbolic" : (warnOnly ? "dialog-warning-symbolic" : "dialog-error-symbolic"),
                         classes: [ok ? "success" : (warnOnly ? "warning" : "error")])
        setAccessibleLabel(icon, ok ? L10n.text(.linux_correct) : L10n.text(.ui_problem))
        return actionRow(title: title, subtitle: ok ? okText : badText, suffix: [icon])
    }
}
