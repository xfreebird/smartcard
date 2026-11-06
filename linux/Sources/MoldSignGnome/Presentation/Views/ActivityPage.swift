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

    init(controller: AppController, window: @escaping () -> UnsafeMutablePointer<GtkWindow>?) {
        self.controller = controller
        self.window = window

        empty = adw_status_page_new()!
        adw_status_page_set_icon_name(empty.opaque, "document-open-recent-symbolic")
        adw_status_page_set_title(empty.opaque, L10n.text(.ui_no_activity_yet))
        adw_status_page_set_description(empty.opaque, L10n.text(.ui_signed_and_verified_documents_and_browser_requests_appear_here))

        group = preferencesGroup(title: L10n.text(.saved_signed))
        let clear = button(L10n.text(.ui_clear_list), classes: ["flat"]) {}
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
        root = vbox(spacing: 0, [navigation, stack.widget])
        onSignal(filterButton, "clicked") { [weak self] in
            guard let self else { return }
            self.history.toggle()
            gtk_button_set_label(self.filterButton.cast(), L10n.text(self.history ? .saved_signed : .saved_history))
            self.renderedKey = ""
            self.render()
        }
        gtk_widget_set_vexpand(root, 1)

        onSignal(clear, "clicked") { [weak self] in
            guard let parent = self?.window() else { return }
            presentClearActivityDialog(parent: parent.widget) { confirmed in
                if confirmed { controller.clearActivity() }
            }
        }
        // a file deleted while the app runs disappears the next time the page is shown
        onSignal(root, "map") { [weak self] in
            self?.renderedKey = ""
            self?.render()
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
        let items = controller.activity.filter { $0.isShowable && (history || ($0.kind == .signed && $0.ok && $0.filePath != nil)) }
        adw_status_page_set_title(empty.opaque, L10n.text(history ? .ui_no_activity_yet : .saved_empty))
        adw_status_page_set_description(empty.opaque, L10n.text(history ? .ui_signed_and_verified_documents_and_browser_requests_appear_here : .saved_hint))
        gtk_stack_set_visible_child_name(stack, items.isEmpty ? "empty" : "list")
        let key = items.map { $0.id.uuidString }.joined()
        guard key != renderedKey else { return }
        renderedKey = key
        clearList(list)
        for item in items {
            let icon: String
            switch item.kind {
            case .bridge: icon = item.ok ? "web-browser-symbolic" : "dialog-error-symbolic"
            case .failed: icon = "dialog-error-symbolic"
            case .signed, .verified: icon = item.ok ? "object-select-symbolic" : "dialog-warning-symbolic"
            }
            var suffix: [Widget] = [label(Format.relative(item.date), classes: ["dim-label", "caption"])]
            if let path = item.filePath {
                suffix.append(button(L10n.text(.ui_verify), classes: ["flat"]) { [weak self] in
                    self?.onVerify?(path)
                })
                suffix.append(button(L10n.text(.ui_open_folder), classes: ["flat"]) { [weak self] in
                    revealInFolder(path, parent: self?.window())
                })
            }
            let tone: [String]
            switch (item.kind, item.ok) {
            case (.bridge, true): tone = []
            case (_, true): tone = ["success"]
            case (.verified, false): tone = ["warning"]
            default: tone = ["error"]
            }
            gtk_list_box_append(list.opaque, actionRow(title: item.title, subtitle: signatureLabels(item.subtitle), icon: icon,
                                                       iconClasses: tone, suffix: suffix))
        }
    }
}
