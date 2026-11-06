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
        filesGroup = preferencesGroup(title: L10n.text(.ui_documents))
        filesList = boxedList()
        groupAdd(filesGroup, filesList)
        append(content, filesGroup)

        dropIcon = image("folder-documents-symbolic", size: 48, classes: ["dim-label"])
        dropTitle = label(L10n.text(.ui_drop_documents_here), classes: ["title-3"], xalign: 0.5)
        dropHint = label(L10n.text(.ui_pdf_pades_t_other_files_xades_t_change_the_format_on_each_row),
                         classes: ["dim-label"], xalign: 0.5, wrap: true)
        gtk_label_set_justify(dropHint.opaque, GTK_JUSTIFY_CENTER)
        let choose = button(L10n.text(.ui_choose_files_2), classes: ["pill"]) {}
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
        resultGroup = preferencesGroup(title: L10n.text(.saved_signed))
        resultList = boxedList()
        groupAdd(resultGroup, resultList)
        append(content, resultGroup)
        gtk_box_reorder_child_after(content.cast(), resultGroup, nil)

        // Footer: status light + the one primary button (docs/10 §4.2, §0.1)
        statusDot = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0)!
        addClasses(statusDot, ["status-dot"])
        gtk_widget_set_valign(statusDot, GTK_ALIGN_CENTER)
        statusLabel = label("", xalign: 0)
        gtk_label_set_ellipsize(statusLabel.opaque, PANGO_ELLIPSIZE_END)
        signButton = button(L10n.text(.ui_sign), classes: ["suggested-action", "pill"]) { controller.signAll() }
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
        chooseFiles(parent: window(), title: L10n.text(.ui_choose_documents_to_sign), multiple: true) { [weak self] paths in
            self?.controller.addFiles(paths)
        }
    }

    private func render() {
        let c = controller
        let hasFiles = !c.signItems.isEmpty

        // The drop zone stays once files exist, compact, under the list.
        setClass(dropZone, "compact", hasFiles)
        setVisible(dropIcon, !hasFiles)
        setLabel(dropTitle, hasFiles ? L10n.text(.linux_drop_more_documents) : L10n.text(.ui_drop_documents_here))
        setVisible(dropHint, !hasFiles)

        renderFiles()
        renderSteps()

        setVisible(errorGroup, c.lastError != nil && !c.isSigning && !c.signItems.contains { $0.error != nil })
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
        gtk_button_set_label(signButton.cast(), count > 1 ? localized(.ui_sign_value_documents, String(count)) : L10n.text(.ui_sign))
        setSensitive(signButton, c.canSign)
        // a disabled primary action must look plainly disabled, not like a pale suggested action
        setClass(signButton, "suggested-action", c.canSign)
        gtk_widget_set_tooltip_text(signButton, c.canSign ? "Ctrl+Enter" : signHint)
    }

    /// Why "Semnează" is disabled (tooltip).
    private var signHint: String {
        let c = controller
        if c.isSigning { return L10n.text(.ui_signing) }
        if c.signItems.isEmpty { return L10n.text(.ui_add_documents_first) }
        return c.statusLight.text
    }

    private func renderFiles() {
        let c = controller
        let key = c.signItems.map { "\($0.id)\($0.format.rawValue)\($0.error ?? "")\(String(describing: $0.stamp))" }.joined() + "\(c.isSigning)"
        setVisible(filesGroup, !c.signItems.isEmpty)
        guard key != filesKey else { return }
        filesKey = key
        clearList(filesList)
        for item in c.signItems {
            let choices = SignFormat.choices(for: item.url)
            let menu = gtk_menu_button_new()!
            gtk_menu_button_set_icon_name(menu.opaque, "view-more-symbolic")
            setAccessibleLabel(menu, L10n.text(.file_options))
            let popover = gtk_popover_new()!
            let actions = vbox(spacing: 4); margins(actions, 8)
            gtk_popover_set_child(popover.cast(), actions)
            gtk_menu_button_set_popover(menu.opaque, popover.cast())
            append(actions, label(L10n.text(.file_signing_type), classes: ["dim-label"]))
            for choice in choices {
                append(actions, button("\(choice == item.format ? "✓  " : "")\(choice.label)") { [weak self] in
                    gtk_popover_popdown(popover.cast())
                    self?.controller.setFormat(choice, for: item.id)
                })
            }
            setSensitive(menu, !c.isSigning)
            let id = item.id
            let remove = iconButton("window-close-symbolic", tooltip: localized(.linux_remove_file, item.url.lastPathComponent)) { [weak self] in
                self?.controller.remove(id)
            }
            setSensitive(remove, !c.isSigning)
            let stampSummary = item.stamp.map { $0.allPages ? L10n.text(.file_stamp_all) : "\(L10n.text(.file_stamp_page)) \($0.page+1)" } ?? L10n.text(.file_stamp_off)
            let formatTag = hbox(spacing: 4, [image("x-office-document-symbolic"), label(item.format.label)])
            addClasses(formatTag, ["file-tag", "format-tag"])
            let tags = hbox(spacing: 6, [formatTag]); gtk_widget_set_halign(tags, GTK_ALIGN_START)
            if item.format == .padesT {
                let stampTag = hbox(spacing: 4, [image("document-edit-symbolic"), label(stampSummary)])
                addClasses(stampTag, ["file-tag", item.stamp == nil ? "stamp-off-tag" : "stamp-tag"])
                append(tags, stampTag)
            }
            if item.format == .padesT {
                let stamp = button(L10n.text(item.stamp == nil ? .stamp_add : .stamp_edit)) { [weak self] in
                    guard let self else { return }
                    gtk_popover_popdown(popover.cast())
                    presentPDFStampEditor(parent: self.window(), item: item, holder: self.controller.certificate?.holder ?? "", applyQueue: { value in
                        for queued in self.controller.signItems where queued.format == .padesT {
                            var template = value
                            if queued.id != item.id { template?.documentSHA256 = nil }
                            self.controller.setStamp(template, for: queued.id)
                        }
                    }) { value in self.controller.setStamp(value, for: id) }
                }
                setSensitive(stamp, !c.isSigning)
                append(actions, stamp)
            }
            append(actions, button(L10n.text(.file_remove)) { [weak self] in gtk_popover_popdown(popover.cast()); self?.controller.remove(id) })
            let title = label(item.url.lastPathComponent, wrap: true)
            let details = vbox(spacing: 4, [title, tags]); gtk_widget_set_hexpand(details, 1)
            if let error = item.error { append(details, label(error, classes: ["error"], wrap: true)) }
            let body = hbox(spacing: 12, [image("x-office-document-symbolic"), details, menu, remove]); margins(body, 12)
            let row = gtk_list_box_row_new()!; gtk_list_box_row_set_child(row.cast(), body)
            addClasses(row, ["file-row"])
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
            if step != .save { append(stepsBox, label(L10n.text(.ui_), classes: ["dim-label"])) }
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
            let open = button(L10n.text(.ui_open_folder), classes: ["flat"]) { [weak self] in
                revealInFolder(url.path, parent: self?.window())
            }
            let openWith = button(L10n.text(.ui_open_with), classes: ["flat"]) { [weak self] in
                openWithApplication(url.path, parent: self?.window())
            }
            let row = actionRow(title: url.lastPathComponent, subtitle: url.deletingLastPathComponent().path,
                                icon: "object-select-symbolic", suffix: [open, openWith])
            adw_action_row_set_activatable_widget(row.cast(), open)
            gtk_list_box_row_set_activatable(row.cast(), 1)
            gtk_list_box_append(resultList.opaque, row)
        }
    }
}
