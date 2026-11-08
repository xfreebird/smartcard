import CAdwaita
import Foundation

/// AdwApplication `md.moldsign.MoldSign`: actions, accelerators, window lifetime and background mode.
final class MoldSignApp {
    static let id = "md.moldsign.MoldSign"

    let app: UnsafeMutablePointer<AdwApplication>
    let controller = AppController()
    private var window: MainWindow?
    private var onboardingPresented = false
    private var onboardingPreview: Bool {
        #if MOLDSIGN_DEMO
        return controller.isDemo && ProcessInfo.processInfo.environment["MSIGN_QA_ONBOARDING"] == "1"
        #else
        return false
        #endif
    }
    private let updates = UpdateChecker()
    private var updateTimer: Task<Void, Never>?
    /// Status light → Quick Settings "Background Apps" (UX-01); created at startup (needs the D-Bus connection).
    private var portal: BackgroundPortal?
    private var held = false
    private var notifiedBackground = false
    /// `--background`: start with the bridge only, no window (XDG autostart / Background portal, LNX-12).
    private var startHidden: Bool
    private let activation: ActivationPolicy

    init(startHidden: Bool, launchState: any LaunchStateStoring = JSONLaunchStateStore()) {
        activation = ActivationPolicy(store: launchState)
        self.startHidden = startHidden
        // G_APPLICATION_HANDLES_OPEN (1 << 2). Recent GLib marks GApplicationFlags as a flag enum, which
        // renames its constants in Swift; the raw value imports the same on every GLib version.
        // Allow isolated Debug onboarding previews alongside the installed instance.
        #if MOLDSIGN_DEMO
        let preview = (ProcessInfo.processInfo.environment["MSIGN_QA_ONBOARDING"] == "1" || ProcessInfo.processInfo.environment["MSIGN_QA_STAMP_PREVIEW"] == "1") && DemoMode.current != nil
        #else
        let preview = false
        #endif
        app = adw_application_new(Self.id, GApplicationFlags(rawValue: (1 << 2) | (preview ? (1 << 5) : 0)))!
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
        controller.applyAppearance()
        installCSS(Style.css)
        addDevelopmentIcons()
        addAction("preferences", accels: ["<Control>comma"]) { [unowned self] in
            presentPreferences(parent: mainWindow.window.widget, controller: controller)
        }
        addAction("check-updates") { [unowned self] in checkUpdates(automatic: false) }
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
        controller.askStamp = { item, holder, origin, done in
            return presentPDFStampEditor(parent: window.window, item: item, holder: holder, requester: origin, cancelled: { done(.cancel) }) {
                done(.proceed($0))
            }
        }
        controller.askPIN = { request, done in
            presentPINDialog(parent: window.window.widget, request: request, completion: done)
        }
        controller.askConsent = { consent, done in
            presentConsentDialog(parent: window.window.widget, consent: consent, completion: done)
        }
        controller.askAgentApproval = { heading, body, action, done in
            presentConfirmDialog(parent: window.window.widget, heading: heading, body: body, action: action,
                                 defaultApprove: false, completion: done)
        }
        controller.askConfirm = { heading, body, action, done in
            presentConfirmDialog(parent: window.window.widget, heading: heading, body: body, action: action, completion: done)
        }
        controller.toast = { window.toast($0) }
        controller.toastWithAction = { text, button, action in window.toast(text, button: button, action: action) }
        controller.reveal = { url in revealInFolder(url.path, parent: window.window) }
        controller.presentWindow = { [unowned self] in presentWindow() }
        let portal = BackgroundPortal(application: app)
        self.portal = portal
        controller.configureLoginStartup = { enabled, done in
            LoginStartup.configure(enabled, portal: portal, completion: done)
        }
        let model = controller
        model.observe { portal.setStatus(model.trayStatus.text) }
        #if MOLDSIGN_DEMO
        if controller.isDemo {
            controller.showDemoPage = { window.show(page: $0) }
            controller.showDemoPreferences = { presentPreferences(parent: window.window.widget, controller: model) }
            var preparedAt: Date?
            var wroteReady = false
            onFrame(window.window.widget) {
                guard !wroteReady, model.demoPrepared, gtk_widget_get_mapped(window.window.widget) != 0 else { return }
                if preparedAt == nil { preparedAt = Date() }
                guard Date().timeIntervalSince(preparedAt!) >= 0.4,
                      let path = ProcessInfo.processInfo.environment["MSIGN_DEMO_READY_FILE"] else { return }
                let marker: [String: Any] = [
                    "ready": true,
                    "width": gtk_widget_get_width(window.window.widget),
                    "height": gtk_widget_get_height(window.window.widget),
                    "scenario": DemoScenario.current?.rawValue ?? "baseline",
                    "page": window.visiblePage,
                    "language": L10n.language ?? "system",
                    "run": ProcessInfo.processInfo.environment["MSIGN_DEMO_RUN_ID"] ?? "",
                ]
                if ProcessInfo.processInfo.environment["MSIGN_QA_STAMP_PREVIEW"] == "1", ProcessInfo.processInfo.environment["MSIGN_QA_FILE_OPTIONS"] != "1", let item = model.signItems.first {
                    let sample = ProcessInfo.processInfo.environment["MSIGN_QA_STAMP_FILE"].map { SignItem(url: URL(fileURLWithPath: $0)) } ?? item
                    presentPDFStampEditor(parent: window.window, item: sample, holder: model.certificate?.holder ?? "", applyQueue: { _ in }) { _ in }
                }
                if let data = try? JSONSerialization.data(withJSONObject: marker, options: [.sortedKeys]) {
                    wroteReady = (try? data.write(to: URL(fileURLWithPath: path), options: .atomic)) != nil
                }
            }
        }
        #endif
        controller.start()
        if !controller.isDemo {
            checkUpdates(automatic: true)
            updateTimer = Task { [weak self] in
                while !Task.isCancelled {
                    do { try await Task.sleep(nanoseconds: 24 * 3600 * 1_000_000_000) } catch { return }
                    onMain { self?.checkUpdates(automatic: true) }
                }
            }
        }
    }

    private func checkUpdates(automatic: Bool) {
        guard !controller.isDemo else { return }
        Task { [weak self] in
            guard let self else { return }
            let result = await updates.check(automatic: automatic)
            onMain { [weak self] in
                guard let self else { return }
                switch result {
                case .available(let url):
                    let launcher = gtk_uri_launcher_new(url.absoluteString)
                    gtk_uri_launcher_launch(launcher, self.mainWindow.window, nil, nil, nil)
                    g_object_unref(launcher?.raw)
                    if !automatic { self.mainWindow.toast(L10n.text(.update_available)) }
                case .current: if !automatic { self.mainWindow.toast(L10n.text(.update_current)) }
                case .failed: if !automatic { self.mainWindow.toast(L10n.text(.update_failed)) }
                case .skipped: break
                }
            }
        }
    }

    private func activate() {
        let destination = activation.destination(backgroundRequested: startHidden,
                                                 backgroundAllowed: controller.shouldRunInBackground)
        startHidden = false
        if destination == .background {
            goBackground()
            return
        }
        presentWindow()
        // First-run onboarding (docs/10 §4.7): once, over the main window; demo sessions stay unobstructed.
        presentOnboardingIfNeeded()
    }

    /// Files from the file manager ("Deschide cu eSemnBun") or the command line go to "Semnează".
    private func open(_ paths: [String]) {
        startHidden = false
        presentWindow()
        presentOnboardingIfNeeded()
        mainWindow.show(page: "sign")
        controller.addFiles(paths)
    }

    private func presentOnboardingIfNeeded() {
        guard !onboardingPresented, !controller.settings.onboardingCompleted, !controller.isDemo || onboardingPreview else { return }
        onboardingPresented = true
        presentOnboardingDialog(parent: mainWindow.window.widget, controller: controller) { [weak self] in
            self?.onboardingPresented = false
        }
    }

    private var mainWindow: MainWindow {
        if let window { return window }
        let window = MainWindow(app: app, controller: controller)
        self.window = window
        onFrame(window.window.widget) { [weak self] in
            guard gtk_widget_get_mapped(window.window.widget) != 0 else { return }
            self?.activation.mainWindowDidPresent()
        }
        #if MOLDSIGN_DEMO
        if controller.isDemo {
            if let size = DemoMode.windowSize { gtk_window_set_default_size(window.window, size.width, size.height) }
            if let page = DemoMode.page { window.show(page: page) }
        }
        #endif
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

    /// Window hidden, bridge still listening: hold the application so it outlives its window, and tell the
    /// Background portal (Flatpak keeps it alive; GNOME lists it under Background Apps with the status text).
    private func goBackground() {
        _ = mainWindow   // dialogs for bridge requests need a (hidden) window to attach to
        if !held {
            held = true
            g_application_hold(app.cast())
        }
        if LoginStartup.sandboxed {
            portal?.requestBackground(reason: L10n.text(.ui_esemnbun_monitors_cards_and_signing_requests_in_the_background),
                                      autostart: controller.settings.launchAtLogin)
        }
        #if os(Linux)
        if !notifiedBackground {
            notifiedBackground = true
            let notification = g_notification_new(L10n.text(.ui_esemnbun_is_running_in_the_background))
            g_notification_set_body(notification, L10n.text(.ui_the_browser_connection_remains_active_open_esemnbun_from_the_applications_list))
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
