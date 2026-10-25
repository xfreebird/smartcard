import CAdwaita
import Foundation

/// AdwApplication `md.moldsign.MoldSign`: actions, accelerators, window lifetime and background mode.
final class MoldSignApp {
    static let id = "md.moldsign.MoldSign"

    let app: UnsafeMutablePointer<AdwApplication>
    let controller = AppController()
    private var window: MainWindow?
    private var held = false
    private var notifiedBackground = false
    /// `--background`: start with the bridge only, no window (XDG autostart / Background portal, LNX-12).
    private var startHidden: Bool

    init(startHidden: Bool) {
        self.startHidden = startHidden
        // G_APPLICATION_HANDLES_OPEN (1 << 2). Recent GLib marks GApplicationFlags as a flag enum, which
        // renames its constants in Swift; the raw value imports the same on every GLib version.
        app = adw_application_new(Self.id, GApplicationFlags(rawValue: 1 << 2))!
        onSignal(app, "startup") { [unowned self] in startup() }
        onSignal(app, "activate") { [unowned self] in activate() }
        onOpenFiles(app) { [unowned self] paths in open(paths) }
        onSignal(app, "shutdown") { [unowned self] in controller.shutdown() }
    }

    func run(arguments: [String]) -> Int32 {
        let copies = arguments.map { strdup($0) }
        defer { copies.forEach { free($0) } }
        var argv: [UnsafeMutablePointer<CChar>?] = copies + [nil]
        return argv.withUnsafeMutableBufferPointer { buffer in
            g_application_run(app.cast(), Int32(arguments.count), buffer.baseAddress)
        }
    }

    // MARK: - Lifecycle

    private func startup() {
        installCSS(Style.css)
        addDevelopmentIcons()
        addAction("preferences", accels: ["<Control>comma"]) { [unowned self] in
            presentPreferences(parent: mainWindow.window.widget, controller: controller)
        }
        addAction("about") { [unowned self] in presentAbout(parent: mainWindow.window.widget) }
        addAction("quit", accels: ["<Control>q"]) { [unowned self] in quit() }
        addAction("open", accels: ["<Control>o"]) { [unowned self] in
            mainWindow.visiblePage == "verify" ? mainWindow.verifyPage.pickFile() : mainWindow.signPage.pickFiles()
        }
        addAction("sign", accels: ["<Control>Return"]) { [unowned self] in controller.signAll() }
        // Alt+1…4 switch pages (keyboard path for the view switcher, docs/10 §6).
        addPageAction(pages: ["sign", "verify", "activity", "card"])
        withCStringArray(["<Control>w"]) { gtk_application_set_accels_for_action(app.cast(), "window.close", $0) }

        let window = mainWindow
        controller.askPIN = { request, done in
            presentPINDialog(parent: window.window.widget, request: request, completion: done)
        }
        controller.askConsent = { consent, done in
            presentConsentDialog(parent: window.window.widget, consent: consent, completion: done)
        }
        controller.askConfirm = { heading, body, action, done in
            presentConfirmDialog(parent: window.window.widget, heading: heading, body: body, action: action, completion: done)
        }
        controller.toast = { window.toast($0) }
        controller.presentWindow = { [unowned self] in presentWindow() }
        controller.start()
    }

    private func activate() {
        if startHidden {
            startHidden = false
            if controller.shouldRunInBackground {
                goBackground()
                return
            }
        }
        presentWindow()
    }

    /// Files from the file manager ("Deschide cu MoldSign") or the command line go to "Semnează".
    private func open(_ paths: [String]) {
        startHidden = false
        presentWindow()
        mainWindow.show(page: "sign")
        controller.addFiles(paths)
    }

    private var mainWindow: MainWindow {
        if let window { return window }
        let window = MainWindow(app: app, controller: controller)
        self.window = window
        onSignalBool(window.window, "close-request") { [unowned self] in
            guard controller.shouldRunInBackground else { return false }   // closes; the app quits with it
            gtk_widget_set_visible(window.window.widget, 0)
            goBackground()
            return true
        }
        return window
    }

    private func presentWindow() {
        mainWindow.present()
        if held {
            held = false
            g_application_release(app.cast())
        }
    }

    /// Window hidden, bridge still listening: hold the application so it outlives its window (LNX-12).
    /// TODO(LNX-12): ask the Background portal (org.freedesktop.portal.Background.RequestBackground)
    /// so GNOME lists MoldSign under "Background Apps" and Flatpak does not kill it; autostart toggle.
    private func goBackground() {
        _ = mainWindow   // dialogs for bridge requests need a (hidden) window to attach to
        if !held {
            held = true
            g_application_hold(app.cast())
        }
        #if os(Linux)
        if !notifiedBackground {
            notifiedBackground = true
            let notification = g_notification_new("MoldSign rulează în fundal")
            g_notification_set_body(notification, "Conexiunea browser rămâne activă. Deschide MoldSign din lista de aplicații.")
            g_application_send_notification(app.cast(), "background", notification)
            g_object_unref(notification?.raw)
        }
        #endif
    }

    private func quit() {
        controller.shutdown()
        g_application_quit(app.cast())
    }

    /// Running from `linux/.build/<config>/`: resolve the app icon from `linux/data/icons` (installed
    /// builds get it from `/usr/share/icons` or `/app/share/icons`).
    private func addDevelopmentIcons() {
        let exe = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let icons = exe.deletingLastPathComponent().appendingPathComponent("../../../data/icons").standardized
        guard FileManager.default.fileExists(atPath: icons.path), let display = gdk_display_get_default() else { return }
        gtk_icon_theme_add_search_path(gtk_icon_theme_get_for_display(display), icons.path)
    }

    // MARK: - Actions

    /// `app.page::<name>` (string-parameter action) with Alt+N accelerators.
    private func addPageAction(pages: [String]) {
        let type = g_variant_type_new("s")
        let action = g_simple_action_new("page", type)!
        g_variant_type_free(type)
        onSignal(action, "activate") { [unowned self] parameter in
            guard let parameter else { return }
            let name = String(cString: g_variant_get_string(OpaquePointer(parameter), nil))
            presentWindow()
            mainWindow.show(page: name)
        }
        g_action_map_add_action(app.opaque, action.opaque)
        g_object_unref(action.raw)
        for (index, page) in pages.enumerated() {
            withCStringArray(["<Alt>\(index + 1)"]) { gtk_application_set_accels_for_action(app.cast(), "app.page::\(page)", $0) }
        }
    }

    private func addAction(_ name: String, accels: [String] = [], _ handler: @escaping () -> Void) {
        let action = g_simple_action_new(name, nil)!
        // GSimpleAction::activate is (action, GVariant *parameter, user_data): the one-argument form.
        onSignal(action, "activate") { _ in handler() }
        g_action_map_add_action(app.opaque, action.opaque)
        if !accels.isEmpty {
            withCStringArray(accels) { gtk_application_set_accels_for_action(app.cast(), "app.\(name)", $0) }
        }
        g_object_unref(action.raw)
    }
}
