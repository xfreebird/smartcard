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
        let choose = button("Alege fișierul", classes: ["pill", "suggested-action"]) {}
        gtk_widget_set_halign(choose, GTK_ALIGN_CENTER)
        let empty = adw_status_page_new()!
        adw_status_page_set_icon_name(empty.opaque, "security-high-symbolic")
        adw_status_page_set_title(empty.opaque, "Verifică semnături")
        adw_status_page_set_description(empty.opaque, "Trage aici un PDF semnat sau o semnătură XAdES (.xml). " +
                                                      "Verificarea se face pe acest calculator.")
        adw_status_page_set_child(empty.opaque, choose)
        addClasses(empty, ["dropzone"])   // the whole empty state is the drop zone
        margins(empty, 24)

        // Checking
        let spinner = gtk_spinner_new()!
        gtk_spinner_start(spinner.opaque)
        gtk_widget_set_size_request(spinner, 32, 32)
        checkingStatus = adw_status_page_new()!
        adw_status_page_set_title(checkingStatus.opaque, "Se verifică…")
        adw_status_page_set_child(checkingStatus.opaque, spinner)

        // Result
        reportsBox = vbox(spacing: 18)
        let again = button("Verifică alt fișier", classes: ["pill"]) {}
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
        chooseFiles(parent: window(), title: "Alege documentul semnat", multiple: false,
                    filters: [("Documente semnate (PDF, XML)", ["pdf", "xml"]), ("Toate fișierele", ["*"])]) { [weak self] paths in
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
        verdict.set(icon: result.icon, title: result.title, body: "\(file.lastPathComponent)\n\(result.subtitle)")
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
    private func signatureGroup(_ report: Validator.Report, index: Int, file: URL) -> Widget {
        let group = preferencesGroup(title: report.signer, description: "Semnătura \(index) · \(report.kind)")
        let list = boxedList()
        gtk_list_box_append(list.opaque, actionRow(title: "Semnat la", subtitle: report.signingTime, icon: "document-edit-symbolic"))
        gtk_list_box_append(list.opaque, actionRow(title: "Marcă temporală", subtitle: report.timestampTime ?? "Fără marcă temporală",
                                                   icon: "document-open-recent-symbolic"))
        gtk_list_box_append(list.opaque, actionRow(title: "Nivel", subtitle: report.level, icon: "security-high-symbolic"))
        gtk_list_box_append(list.opaque, check("Integritate", ok: report.contentIntact,
                                               okText: "Documentul nu a fost modificat după semnare",
                                               badText: "Conținutul diferă de cel semnat"))
        gtk_list_box_append(list.opaque, check("Semnătură", ok: report.signatureValid,
                                               okText: "Semnătura RSA corespunde certificatului",
                                               badText: "Semnătura nu corespunde"))
        gtk_list_box_append(list.opaque, check("Lanț de încredere", ok: report.chainTrusted,
                                               okText: "Emis de MDQSign, ancorat în mdtrustca",
                                               badText: "Lanț necunoscut sau incomplet", warnOnly: true))

        let details = adw_expander_row_new()!
        adw_preferences_row_set_title(details.cast(), "Detalii tehnice")
        let detailRows: [(String, String)] = [
            ("Format", report.kind),
            ("Identificator", report.name),
            ("Rezumat", report.summary),
        ]
        for (title, value) in detailRows {
            let row = actionRow(title: title, subtitle: value, subtitleSelectable: true)
            addClasses(row, ["property"])
            adw_expander_row_add_row(details.cast(), row)
        }
        if file.pathExtension.lowercased() == "xml" && !report.contentIntact {
            // TODO(LNX-09): inline picker row for the signed file(s) of a detached signature (docs/10 §4.2).
            adw_expander_row_add_row(details.cast(), actionRow(
                title: "Semnătură detașată",
                subtitle: "Fișierele semnate trebuie să fie în același dosar cu semnătura .xml"))
        }
        gtk_list_box_append(list.opaque, details)
        groupAdd(group, list)
        return group
    }

    private func check(_ title: String, ok: Bool, okText: String, badText: String, warnOnly: Bool = false) -> Widget {
        let icon = image(ok ? "object-select-symbolic" : (warnOnly ? "dialog-warning-symbolic" : "dialog-error-symbolic"),
                         classes: [ok ? "success" : (warnOnly ? "warning" : "error")])
        setAccessibleLabel(icon, ok ? "Corect" : "Problemă")
        return actionRow(title: title, subtitle: ok ? okText : badText, suffix: [icon])
    }
}
