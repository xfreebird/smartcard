import CAdwaita

/// Common GTK file actions for library entries, signing results and the document inspector.
struct DocumentActions {
    let controls: Widget
    let reveal: Widget

    init(path: String, parent: @escaping () -> UnsafeMutablePointer<GtkWindow>?, showsFolderLabel: Bool = false) {
        let openWith = button(L10n.text(.ui_open_with)) { DesktopLauncher.openFile(path, parent()) }
        gtk_button_set_child(openWith.cast(), hbox(spacing: 6, [
            image("document-open-symbolic"), label(L10n.text(.ui_open_with))
        ]))
        setAccessibleLabel(openWith, L10n.text(.ui_open_with))
        reveal = iconButton("folder-open-symbolic", tooltip: L10n.text(.ui_open_folder), classes: []) {
            DesktopLauncher.revealFile(path, parent())
        }
        if showsFolderLabel {
            gtk_button_set_child(reveal.cast(), hbox(spacing: 6, [
                image("folder-open-symbolic"), label(L10n.text(.ui_open_folder))
            ]))
        }
        controls = hbox(classes: ["linked"], [openWith, reveal])
        gtk_widget_set_valign(controls, GTK_ALIGN_CENTER)
    }
}
