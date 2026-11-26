import CAdwaita
import Foundation

// File access through GTK: GtkFileDialog (portal-aware: works inside Flatpak), GtkDropTarget with
// GdkFileList, and GtkFileLauncher to reveal results in the file manager.

/// Opens the native/portal file chooser; `completion` gets local paths (empty on cancel).
func chooseFiles(parent: UnsafeMutablePointer<GtkWindow>?, title: String, multiple: Bool,
                 filters: [(name: String, suffixes: [String])] = [], completion: @escaping ([String]) -> Void) {
    let dialog = gtk_file_dialog_new()
    gtk_file_dialog_set_title(dialog, title)
    gtk_file_dialog_set_modal(dialog, 1)
    if !filters.isEmpty {
        let store = g_list_store_new(gtk_file_filter_get_type())
        for f in filters {
            let filter = gtk_file_filter_new()
            gtk_file_filter_set_name(filter, f.name)
            f.suffixes.forEach { gtk_file_filter_add_suffix(filter, $0) }
            g_list_store_append(store, filter?.raw)
            g_object_unref(filter?.raw)
        }
        gtk_file_dialog_set_filters(dialog, store)
        g_object_unref(store?.raw)
    }
    let (callback, data) = asyncReady { result in
        var error: UnsafeMutablePointer<GError>?
        var paths: [String] = []
        if multiple {
            if let list = gtk_file_dialog_open_multiple_finish(dialog, result, &error) {
                for i in 0..<g_list_model_get_n_items(list) {
                    guard let item = g_list_model_get_item(list, i) else { continue }
                    if let path = filePath(OpaquePointer(item)) { paths.append(path) }
                    g_object_unref(item)
                }
                g_object_unref(list.raw)
            }
        } else if let file = gtk_file_dialog_open_finish(dialog, result, &error) {
            if let path = filePath(file) { paths.append(path) }
            g_object_unref(file.raw)
        }
        _ = takeError(error)   // dismissed by the user: nothing to report
        g_object_unref(dialog?.raw)
        completion(paths)
    }
    if multiple {
        gtk_file_dialog_open_multiple(dialog, parent, nil, callback, data)
    } else {
        gtk_file_dialog_open(dialog, parent, nil, callback, data)
    }
}

/// Hands a file to the desktop ("Open folder", "Open with"). The app uses the GTK launchers below; tests replace
/// them, because a test run must never start the file manager or another application.
enum DesktopLauncher {
    static var revealFile: (_ path: String, _ parent: UnsafeMutablePointer<GtkWindow>?) -> Void = revealInFolder
    static var openFile: (_ path: String, _ parent: UnsafeMutablePointer<GtkWindow>?) -> Void = openWithApplication
}

/// Shows the file selected in its folder (file manager via the OpenURI portal / D-Bus FileManager1).
func revealInFolder(_ path: String, parent: UnsafeMutablePointer<GtkWindow>?) {
    let file = g_file_new_for_path(path)
    let launcher = gtk_file_launcher_new(file)
    g_object_unref(file?.raw)
    let (callback, data) = asyncReady { result in
        var error: UnsafeMutablePointer<GError>?
        _ = gtk_file_launcher_open_containing_folder_finish(launcher, result, &error)
        _ = takeError(error)
        g_object_unref(launcher?.raw)
    }
    gtk_file_launcher_open_containing_folder(launcher, parent, nil, callback, data)
}

/// Native Open With selection for handing a result to another installed app (including sharing apps).
func openWithApplication(_ path: String, parent: UnsafeMutablePointer<GtkWindow>?) {
    let file = g_file_new_for_path(path)
    let launcher = gtk_file_launcher_new(file)
    g_object_unref(file?.raw)
    gtk_file_launcher_set_always_ask(launcher, 1)
    let (callback, data) = asyncReady { result in
        var error: UnsafeMutablePointer<GError>?
        _ = gtk_file_launcher_launch_finish(launcher, result, &error)
        _ = takeError(error)
        g_object_unref(launcher?.raw)
    }
    gtk_file_launcher_launch(launcher, parent, nil, callback, data)
}

/// Accepts files dragged from the file manager onto `widget` (GTK sets `:drop(active)` while hovering).
func addFileDropTarget(_ widget: Widget, _ onFiles: @escaping ([String]) -> Void) {
    let target = gtk_drop_target_new(gdk_file_list_get_type(), GDK_ACTION_COPY)
    onDrop(target!) { value in
        guard let list = g_value_get_boxed(value) else { return false }
        var paths: [String] = []
        // GSList of GFile*, owned by the GdkFileList (free the list container only).
        var node = gdk_file_list_get_files(OpaquePointer(list))
        let head = node
        while let current = node {
            if let file = current.pointee.data, let path = filePath(OpaquePointer(file)) { paths.append(path) }
            node = current.pointee.next
        }
        g_slist_free(head)
        guard !paths.isEmpty else { return false }
        onFiles(paths)
        return true
    }
    gtk_widget_add_controller(widget, target)
}
