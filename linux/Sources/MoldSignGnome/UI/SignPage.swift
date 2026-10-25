import CAdwaita
import Foundation

/// docs/10 §4.2 + §0 "Semnează": card wallet on top (status first, the cards are the selector), drop →
/// automatic format chips → one primary button; the action bar carries the status light (LNX-09, UX-01/02/07).
final class SignPage {
    let root: Widget
    private let controller: AppController
    private let window: () -> UnsafeMutablePointer<GtkWindow>?

    private let dropZone: Widget
    private let dropTitle: Widget
    private let dropHint: Widget
    private let dropIcon: Widget
    private let filesGroup: Widget
    private let filesList: Widget
    private let stepsBox: Widget
    private let errorGroup: Widget
    private let errorRow: Widget
    private let resultGroup: Widget
    private let resultList: Widget
    private let statusDot: Widget
    private let statusLabel: Widget
    private let signButton: Widget
    let wallet: CardWallet

    private var filesKey = ""
    private var resultKey = ""

    init(controller: AppController, window: @escaping () -> UnsafeMutablePointer<GtkWindow>?) {
        self.controller = controller
        self.window = window

        let content = vbox(spacing: 18)
        margins(content, 24)
        gtk_widget_set_margin_top(content, 6)

        // Card wallet: which card signs, and whether it can (docs/10 §0.2); full width above the clamp
        wallet = CardWallet(controller: controller)
        gtk_widget_set_margin_top(wallet.root, 12)

        // Documents: the list of added files, then the drop zone (large while empty, compact under the list after)
        filesGroup = preferencesGroup(title: "Documente")
        filesList = boxedList()
        groupAdd(filesGroup, filesList)
        append(content, filesGroup)

        dropIcon = image("folder-documents-symbolic", size: 48, classes: ["dim-label"])
        dropTitle = label("Trage documentele aici", classes: ["title-3"], xalign: 0.5)
        dropHint = label("PDF → PAdES-T, alte fișiere → XAdES-T; formatul se poate schimba pe fiecare rând",
                         classes: ["dim-label"], xalign: 0.5, wrap: true)
        gtk_label_set_justify(dropHint.opaque, GTK_JUSTIFY_CENTER)
        let choose = button("Alege fișiere…", classes: ["pill"]) {}
        gtk_widget_set_halign(choose, GTK_ALIGN_CENTER)
        dropZone = vbox(spacing: 8, classes: ["dropzone"], [dropIcon, dropTitle, dropHint, choose])
        append(content, dropZone)

        // StepProgress
        stepsBox = hbox(spacing: 10, classes: ["steps"])
        gtk_widget_set_halign(stepsBox, GTK_ALIGN_CENTER)
        append(content, stepsBox)

        // Error (stays until the next attempt; the toast is the transient copy)
        errorGroup = preferencesGroup(title: nil)
        errorRow = actionRow(title: "", icon: "dialog-error-symbolic")
        addClasses(errorRow, ["error"])
        let errorList = boxedList()
        gtk_list_box_append(errorList.opaque, errorRow)
        groupAdd(errorGroup, errorList)
        append(content, errorGroup)

        // Result
        resultGroup = preferencesGroup(title: "Semnat cu succes")
        resultList = boxedList()
        groupAdd(resultGroup, resultList)
        append(content, resultGroup)

        // Footer: status light + the one primary button (docs/10 §4.2, §0.1)
        statusDot = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0)!
        addClasses(statusDot, ["status-dot"])
        gtk_widget_set_valign(statusDot, GTK_ALIGN_CENTER)
        statusLabel = label("", xalign: 0)
        gtk_label_set_ellipsize(statusLabel.opaque, PANGO_ELLIPSIZE_END)
        signButton = button("Semnează", classes: ["suggested-action", "pill"]) { controller.signAll() }
        let actionBar = gtk_action_bar_new()!
        let statusBox = hbox(spacing: 8, [statusDot, statusLabel])
        gtk_widget_set_margin_start(statusBox, 6)
        gtk_widget_set_margin_end(signButton, 6)
        for w in [statusBox, signButton] {
            gtk_widget_set_margin_top(w, 6)
            gtk_widget_set_margin_bottom(w, 6)
        }
        gtk_action_bar_pack_start(actionBar.opaque, statusBox)
        gtk_action_bar_pack_end(actionBar.opaque, signButton)

        root = vbox(spacing: 0, classes: ["drop-page"], [scrolledPage(content, top: wallet.root), actionBar])

        onSignal(choose, "clicked") { [weak self] in self?.pickFiles() }
        addFileDropTarget(root) { paths in controller.addFiles(paths) }
        controller.observe { [weak self] in self?.render() }
    }

    /// "Alege fișiere" / Ctrl+O.
    func pickFiles() {
        chooseFiles(parent: window(), title: "Alege documentele de semnat", multiple: true) { [weak self] paths in
            self?.controller.addFiles(paths)
        }
    }

    private func render() {
        let c = controller
        let hasFiles = !c.signItems.isEmpty

        // The drop zone stays once files exist, compact, under the list.
        setClass(dropZone, "compact", hasFiles)
        setVisible(dropIcon, !hasFiles)
        setLabel(dropTitle, hasFiles ? "Trage aici alte documente" : "Trage documentele aici")
        setVisible(dropHint, !hasFiles)

        renderFiles()
        renderSteps()

        setVisible(errorGroup, c.lastError != nil && !c.isSigning)
        if let error = c.lastError {
            adw_preferences_row_set_title(errorRow.cast(), escapeMarkup(error.message))
            adw_action_row_set_subtitle(errorRow.cast(), escapeMarkup(error.recovery))
        }
        renderResults()

        // Footer: the status light, never color alone (the label says the same)
        let light = c.statusLight
        setLabel(statusLabel, light.text)
        gtk_widget_set_tooltip_text(statusLabel, light.text)
        for name in ["ready", "reader", "busy", "error"] {
            setClass(statusDot, name, light.light.rawValue == name)
        }
        setVisible(statusDot, light.light != .idle)   // idle: no dot, the text alone (docs/10 §0.1)
        let count = c.signItems.count
        gtk_button_set_label(signButton.cast(), count > 1 ? "Semnează \(count) documente" : "Semnează")
        setSensitive(signButton, c.canSign)
        // a disabled primary action must look plainly disabled, not like a pale suggested action
        setClass(signButton, "suggested-action", c.canSign)
        gtk_widget_set_tooltip_text(signButton, c.canSign ? "Ctrl+Enter" : signHint)
    }

    /// Why "Semnează" is disabled (tooltip).
    private var signHint: String {
        let c = controller
        if c.isSigning { return "Se semnează…" }
        if c.signItems.isEmpty { return "Adaugă mai întâi documentele" }
        return c.statusLight.text
    }

    private func renderFiles() {
        let c = controller
        let key = c.signItems.map { "\($0.id)\($0.format.rawValue)" }.joined() + "\(c.isSigning)"
        setVisible(filesGroup, !c.signItems.isEmpty)
        guard key != filesKey else { return }
        filesKey = key
        clearList(filesList)
        for item in c.signItems {
            let chip: Widget
            let choices = SignFormat.choices(for: item.url)
            if choices.count == 1 {
                chip = label(item.format.label, classes: ["chip"])
            } else {
                chip = withCStringArray(choices.map(\.label)) { gtk_drop_down_new_from_strings($0)! }
                addClasses(chip, ["chip"])
                gtk_drop_down_set_selected(chip.opaque, guint(choices.firstIndex(of: item.format) ?? 0))
                setAccessibleLabel(chip, "Format pentru \(item.url.lastPathComponent)")
                let id = item.id
                onSignal(chip, "notify::selected") { [weak self] _ in
                    let index = Int(gtk_drop_down_get_selected(chip.opaque))
                    if choices.indices.contains(index) { self?.controller.setFormat(choices[index], for: id) }
                }
            }
            setSensitive(chip, !c.isSigning)
            let id = item.id
            let remove = iconButton("window-close-symbolic", tooltip: "Elimină \(item.url.lastPathComponent)") { [weak self] in
                self?.controller.remove(id)
            }
            setSensitive(remove, !c.isSigning)
            let row = actionRow(title: item.url.lastPathComponent, subtitle: item.sizeText,
                                icon: "x-office-document-symbolic", suffix: [chip, remove])
            gtk_list_box_append(filesList.opaque, row)
        }
    }

    private func renderSteps() {
        clearBox(stepsBox)
        guard let current = controller.currentStep else {
            setVisible(stepsBox, false)
            return
        }
        setVisible(stepsBox, true)
        for step in UIStep.allCases {
            let marker: Widget
            let state: String
            if step.rawValue < current.rawValue {
                marker = image("object-select-symbolic", classes: ["success"])
                state = "done"
            } else if step == current {
                marker = gtk_spinner_new()!
                gtk_spinner_start(marker.opaque)
                state = "active"
            } else {
                marker = image("radio-symbolic")
                state = "pending"
            }
            append(stepsBox, hbox(spacing: 6, classes: ["step", state], [marker, label(step.label)]))
            if step != .save { append(stepsBox, label("›", classes: ["dim-label"])) }
        }
    }

    private func renderResults() {
        let signed = controller.lastSigned
        setVisible(resultGroup, !signed.isEmpty)
        let key = signed.map(\.path).joined(separator: "\n")
        guard key != resultKey else { return }
        resultKey = key
        clearList(resultList)
        for url in signed {
            let open = button("Deschide dosarul", classes: ["flat"]) { [weak self] in
                revealInFolder(url.path, parent: self?.window())
            }
            let row = actionRow(title: url.lastPathComponent, subtitle: url.deletingLastPathComponent().path,
                                icon: "object-select-symbolic", suffix: [open])
            gtk_list_box_append(resultList.opaque, row)
        }
    }
}
