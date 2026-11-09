import CAdwaita
import Foundation

/// "Activitate": the last 100 signatures, verifications and browser requests (LNX-09). File entries show only
/// while the file still exists (checked on every render and once a minute); "Golește lista" asks first.
final class ActivityPage {
    var onVerify: ((String) -> Void)?
    let root: Widget
    private let controller: AppController
    private let window: () -> UnsafeMutablePointer<GtkWindow>?
    private let stack: OpaquePointer
    private let list: Widget
    private let group: Widget
    private var renderedKey = ""
    private var history = false
    private let empty: Widget
    private let filterButton: Widget
    private let clearButton: Widget
    private var detailsOpen = false
    private var protection: FileProtectionDialog?
    private var rowPaths: [UnsafeMutableRawPointer: String] = [:]

    init(controller: AppController, window: @escaping () -> UnsafeMutablePointer<GtkWindow>?) {
        self.controller = controller
        self.window = window

        empty = adw_status_page_new()!
        adw_status_page_set_icon_name(empty.opaque, "document-open-recent-symbolic")
        adw_status_page_set_title(empty.opaque, L10n.text(.ui_no_activity_yet))
        adw_status_page_set_description(empty.opaque, L10n.text(.ui_signed_and_verified_documents_and_browser_requests_appear_here))

        group = preferencesGroup(title: L10n.text(.saved_signed))
        clearButton = iconButton("edit-clear-all-symbolic", tooltip: L10n.text(.ui_clear_list)) {}
        let clear = clearButton
        gtk_widget_set_visible(clear, 0)
        adw_preferences_group_set_header_suffix(group.cast(), clear)
        list = boxedList()
        groupAdd(group, list)
        margins(group, 24)

        stack = OpaquePointer(gtk_stack_new()!)
        gtk_stack_add_named(stack, empty, "empty")
        gtk_stack_add_named(stack, scrolledPage(group), "list")
        filterButton = button(L10n.text(.saved_history), classes: ["flat"]) {}
        let navigation = hbox(spacing: 12, [label(L10n.text(.saved_title), classes: ["title-2"]), filterButton])
        margins(navigation, 18)
        let protect = button(L10n.text(.protect_title) + " · " + L10n.text(.protect_hint), classes: ["pill"]) {}
        margins(protect, 18)
        root = vbox(spacing: 0, [navigation, protect, stack.widget])
        onSignal(protect, "clicked") { [weak self] in
            guard let self, let parent = self.window(), self.protection == nil else { return }
            self.protection = FileProtectionDialog(controller: controller, parent: parent) { [weak self] in self?.protection = nil }
        }
        onSignal(list, "row-activated") { [weak self] row in
            guard let self, let row, let path = self.rowPaths[row] else { return }
            self.presentDetails(path)
        }
        onSignal(filterButton, "clicked") { [weak self] in
            guard let self else { return }
            self.history.toggle()
            gtk_button_set_label(self.filterButton.cast(), L10n.text(self.history ? .saved_signed : .saved_history))
            self.renderedKey = ""
            self.render()
        }
        gtk_widget_set_vexpand(root, 1)

        onSignal(clear, "clicked") { [weak self] in
            guard let self, let parent = self.window() else { return }
            if self.history {
                presentClearActivityDialog(parent: parent.widget) { confirmed in
                    if confirmed { controller.clearActivity() }
                }
            } else {
                let items = controller.signedDocuments
                presentDeleteSignedDocumentsDialog(parent: parent.widget, items: items) { confirmed in
                    if confirmed { controller.deleteSignedDocuments(items) }
                }
            }
        }
        // a file deleted while the app runs disappears the next time the page is shown
        onSignal(root, "map") { [weak self] in
            self?.renderedKey = ""
            self?.render()
            #if MOLDSIGN_DEMO
            if let self, controller.isDemo, DemoMode.screenshotCapture,
               ProcessInfo.processInfo.environment["MSIGN_CAPTURE_DIALOG"]?.hasPrefix("protect-")==true,
               let parent=self.window(), self.protection==nil {
                self.protection=FileProtectionDialog(controller:controller,parent:parent){[weak self] in self?.protection=nil}
            }
            #endif
        }
        controller.observe { [weak self] in self?.render() }
        // Relative times ("acum 2 min") age: refresh once a minute.
        every(seconds: 60) { [weak self] in
            self?.renderedKey = ""
            self?.render()
            return self != nil
        }
    }

    private func render() {
        adw_preferences_group_set_title(group.cast(), L10n.text(history ? .saved_history : .saved_signed))
        gtk_widget_set_visible(clearButton, 1)
        gtk_widget_set_tooltip_text(clearButton, L10n.text(history ? .ui_clear_the_list : .saved_delete_all))
        let items = (history ? controller.activity : controller.signedDocuments).filter(\.isShowable)
        gtk_widget_set_sensitive(clearButton, items.isEmpty ? 0 : 1)
        adw_status_page_set_title(empty.opaque, L10n.text(history ? .ui_no_activity_yet : .saved_empty))
        adw_status_page_set_description(empty.opaque, L10n.text(history ? .ui_signed_and_verified_documents_and_browser_requests_appear_here : .saved_hint))
        gtk_stack_set_visible_child_name(stack, items.isEmpty ? "empty" : "list")
        let key = items.map { $0.id.uuidString }.joined()
        guard key != renderedKey else { return }
        renderedKey = key
        rowPaths.removeAll()
        clearList(list)
        for item in items {
            let icon: String
            switch item.kind {
            case .bridge: icon = item.ok ? "web-browser-symbolic" : "dialog-error-symbolic"
            case .failed: icon = "dialog-error-symbolic"
            case .signed, .verified: icon = item.ok ? "object-select-symbolic" : "dialog-warning-symbolic"
            }
            let tone: [String]
            switch (item.kind, item.ok) {
            case (.bridge, true): tone = []
            case (_, true): tone = ["success"]
            case (.verified, false): tone = ["warning"]
            default: tone = ["error"]
            }
            let title = label(item.title)
            gtk_label_set_ellipsize(title.opaque, PANGO_ELLIPSIZE_MIDDLE)
            gtk_widget_set_hexpand(title, 1)
            let heading = hbox(spacing: 8, [image(icon, classes: tone), title])
            let subtitle = label(signatureLabels(item.subtitle), classes: ["dim-label"], wrap: true)
            let content = vbox(spacing: 8, [heading, subtitle,
                label(Format.relative(item.date), classes: ["dim-label", "caption"])])
            if let path = item.filePath {
                append(content, hbox(spacing: 8, [
                    button(L10n.text(.saved_details), classes: ["flat"]) { [weak self] in self?.presentDetails(path) },
                    iconButton("folder-open-symbolic", tooltip: L10n.text(.ui_open_folder)) { [weak self] in
                        revealInFolder(path, parent: self?.window())
                    }
                ]))
            }
            if !history {
                append(content, button(L10n.text(.saved_delete), classes: ["flat", "destructive-action"]) { [weak self] in
                    guard let self, let parent = self.window() else { return }
                    presentDeleteSignedDocumentsDialog(parent: parent.widget, items: [item]) { confirmed in
                        if confirmed { self.controller.deleteSignedDocuments([item]) }
                    }
                })
            }
            margins(content, 12)
            let row = gtk_list_box_row_new()!
            gtk_list_box_row_set_child(row.cast(), content)
            gtk_list_box_row_set_activatable(row.cast(), item.filePath == nil ? 0 : 1)
            if let path = item.filePath {
                rowPaths[row.raw] = path
            }
            gtk_list_box_append(list.opaque, row)
        }
    }

    private func presentDetails(_ path: String) {
        guard !detailsOpen, let parent = window() else { return }
        detailsOpen = true
        let dialog = adw_dialog_new()!
        adw_dialog_set_title(dialog, L10n.text(.saved_details))
        adw_dialog_set_content_width(dialog, 560)
        adw_dialog_set_content_height(dialog, 640)
        let header = adw_header_bar_new()!
        adw_header_bar_set_title_widget(header.opaque, label(L10n.text(.saved_details), classes: ["heading"]))
        let content = vbox(spacing: 18, [label(URL(fileURLWithPath: path).lastPathComponent, wrap: true)])
        margins(content, 18)
        let spinner = gtk_spinner_new()!
        gtk_spinner_start(spinner.opaque)
        append(content, hbox(spacing: 8, [spinner, label(L10n.text(.ui_verifying))]))
        let toolbar = adw_toolbar_view_new()!
        adw_toolbar_view_add_top_bar(toolbar.opaque, header)
        adw_toolbar_view_set_content(toolbar.opaque, scrolledPage(content))
        adw_dialog_set_child(dialog, toolbar)
        var open = true
        onSignal(dialog, "closed") { [weak self] in
            open = false
            self?.detailsOpen = false
        }
        adw_dialog_present(dialog, parent.widget)
        var generation = UUID()
        func inspect(_ companions: [URL]) {
            generation = UUID()
            let request = generation
            clearBox(content)
            append(content, label(L10n.text(.ui_verifying)))
            controller.inspectDocument(path: path, companions: companions) { reports in
                guard generation == request else { return }
                guard open else { return } // The user may close while validation is still running.
                clearBox(content)
                append(content, label(URL(fileURLWithPath: path).lastPathComponent, wrap: true))
                guard let reports else {
                    append(content, label(L10n.text(.saved_unavailable), classes: ["error"], wrap: true))
                    return
                }
                let result = Verdict(reports)
                append(content, label(reports.isEmpty ? L10n.text(.ui_no_signature_found) : result.title,
                                      classes: ["title-2", result.styleClass], wrap: true))
                append(content, label(reports.isEmpty ? L10n.text(.ui_the_document_contains_no_recognized_signature) : result.subtitle,
                                      classes: ["dim-label"], wrap: true))
                if URL(fileURLWithPath: path).pathExtension.lowercased() == "xml" {
                    append(content, button(L10n.text(.verify_choose_originals)) {
                        chooseFiles(parent: parent, title: L10n.text(.verify_choose_originals), multiple: true) { paths in
                            guard open, !paths.isEmpty else { return }
                            inspect(paths.map { URL(fileURLWithPath: $0) })
                        }
                    })
                }
                for (index, report) in reports.enumerated() {
                    append(content, VerifyPage.signatureGroup(report, index: index + 1, file: URL(fileURLWithPath: path)))
                }
            }
        }
        inspect([])
    }

}
