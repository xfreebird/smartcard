import CAdwaita
import Foundation

/// "Activitate": the last 100 signatures, verifications and browser requests (LNX-09). File entries show only
/// while the file still exists (checked on every render and once a minute); "Golește lista" asks first.
final class ActivityPage {
    let root: Widget
    private let controller: AppController
    private let window: () -> UnsafeMutablePointer<GtkWindow>?
    private let stack: OpaquePointer
    private let list: Widget
    private var renderedKey = ""

    init(controller: AppController, window: @escaping () -> UnsafeMutablePointer<GtkWindow>?) {
        self.controller = controller
        self.window = window

        let empty = adw_status_page_new()!
        adw_status_page_set_icon_name(empty.opaque, "document-open-recent-symbolic")
        adw_status_page_set_title(empty.opaque, "Nicio activitate")
        adw_status_page_set_description(empty.opaque, "Documentele semnate și verificate și cererile din browser apar aici.")

        let group = preferencesGroup(title: "Recente")
        let clear = button("Golește lista", classes: ["flat"]) {}
        adw_preferences_group_set_header_suffix(group.cast(), clear)
        list = boxedList()
        groupAdd(group, list)
        margins(group, 24)

        stack = OpaquePointer(gtk_stack_new()!)
        gtk_stack_add_named(stack, empty, "empty")
        gtk_stack_add_named(stack, scrolledPage(group), "list")
        root = stack.widget
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
        let items = controller.activity.filter(\.isShowable)
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
                suffix.append(iconButton("folder-open-symbolic", tooltip: "Deschide dosarul") { [weak self] in
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
            gtk_list_box_append(list.opaque, actionRow(title: item.title, subtitle: item.subtitle, icon: icon,
                                                       iconClasses: tone, suffix: suffix))
        }
    }
}
