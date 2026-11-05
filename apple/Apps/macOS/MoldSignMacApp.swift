import SwiftUI
import MoldSignKit

/// macOS menu-bar agent (LSUIElement): status icon + popover, main window on demand, Settings (MAC-01, MAC-09).
@main
struct MoldSignMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"

    private var showsMenuBarItem: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["MSIGN_QA_HIDE_TRAY"] != "1"
        #else
        true
        #endif
    }

    var body: some Scene {
        let _ = language // Recompute scene titles and the status item's accessibility label.
        MenuBarExtra(isInserted: .constant(showsMenuBarItem)) {
            MenuBarPopover()
                .environment(appDelegate.model)
                .appPreferences()
        } label: {
            MenuBarIcon(connected: appDelegate.model.cardConnected, label: appDelegate.model.trayLabel)
        }
        .menuBarExtraStyle(.window)

        Window(L10n.text(.ui_esemnbun), id: "main") {
            MainWindowView()
                .environment(appDelegate.model)
                .appPreferences()
                .frame(minWidth: 860, minHeight: 580)
                .onAppear { AppPreferencesStore.defaults.set(true, forKey: "didPresentMainWindow") }
        }
        .defaultLaunchBehavior(.suppressed)

        Settings {
            SettingsView()
                .environment(appDelegate.model)
                .appPreferences()
        }

        Window(L10n.text(.about_app_title), id: "about") {
            AboutContent().frame(width: 420, height: 340).appPreferences()
                .background(WindowReader { WindowPresentation.shared.register($0, for: .about) })
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .help) {
                Button("eSemnBun Help") {
                    NSWorkspace.shared.open(URL(string: "https://esemnbun.md/docs/start/")!)
                }
            }
            CommandGroup(replacing: .appInfo) { AboutMenuCommand() }
            CommandGroup(replacing: .appSettings) { SettingsMenuCommand() }
            #if !APP_STORE
            CommandGroup(after: .appInfo) { UpdateMenuCommand() }
            #endif
        }
    }
}

private struct AboutMenuCommand: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button(L10n.text(.about_app_title)) {
            WindowPresentation.shared.present(.about) { openWindow(id: "about") }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private let authPanel = AuthPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self
        authPanel.attach(model)
        model.presentInsertedCard = {
            NotificationCenter.default.post(name: .showInsertedCard, object: nil)
        }
        model.start()
        #if !APP_STORE
        AppUpdateChecker.shared.start()
        #endif
        observeWindows()
        let firstLaunch = !AppPreferencesStore.defaults.bool(forKey: "didPresentMainWindow")
        if firstLaunch || ProcessInfo.processInfo.arguments.contains("--show-main-window") {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                NotificationCenter.default.post(name: .showInsertedCard, object: nil)
            }
        }
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["MSIGN_DEMO_CARDS"] != nil, env["MSIGN_DEMO_PREVIEW"] != "0" { showDesignPreviews() }
        #endif
    }

    #if DEBUG
    /// Design QA with demo cards: the popover can't be opened programmatically, so show it (and the main
    /// window) in plain windows. Debug builds only.
    private var previewWindows: [NSWindow] = []

    private func showDesignPreviews() {
        if ProcessInfo.processInfo.environment["MSIGN_DEMO_DARK"] != nil { NSApp.appearance = NSAppearance(named: .darkAqua) }
        let popover = NSHostingController(rootView: MenuBarPopover().environment(model).appPreferences())
        let main = NSHostingController(rootView: MainWindowView().environment(model).appPreferences().frame(width: 980, height: 700))
        for (title, controller, origin) in [("Popover preview", popover as NSViewController, NSPoint(x: 60, y: 120)),
                                            ("eSemnBun preview", main as NSViewController, NSPoint(x: 420, y: 80))] {
            let window = NSWindow(contentViewController: controller)
            window.title = title
            window.setFrameOrigin(origin)
            window.makeKeyAndOrderFront(nil)
            previewWindows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)
        if let main = previewWindows.last { WindowPresentation.bringForward(main) }
    }
    #endif

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NotificationCenter.default.post(name: .showInsertedCard, object: nil)
        return false
    }

    // MARK: Dock / Cmd-Tab presence

    /// A menu-bar agent (LSUIElement) has no Dock icon and is missing from Cmd-Tab. While the main window or Settings
    /// is open the app becomes a regular app; when the last such window closes it goes back to the menu bar only.
    private func observeWindows() {
        // occlusion changes whenever a window is ordered in or out, even if it never becomes key
        let names = [NSWindow.didChangeOcclusionStateNotification, NSWindow.didBecomeKeyNotification,
                     NSWindow.didMiniaturizeNotification, NSWindow.willCloseNotification]
        for name in names {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                let closing = name == NSWindow.willCloseNotification ? note.object as? NSWindow : nil
                MainActor.assumeIsolated {
                    if let closing { WindowPresentation.shared.unregister(closing) }
                    self?.updateActivationPolicy(closing: closing)
                }
            }
        }
    }

    private func updateActivationPolicy(closing: NSWindow?) {
        let hasAppWindow = NSApp.windows.contains { window in
            window !== closing && (window.isVisible || window.isMiniaturized) && window.canBecomeMain
                && window.styleMask.contains(.titled) && !(window is NSPanel)
                && !window.className.contains("MenuBarExtra")
        }
        let policy: NSApplication.ActivationPolicy =
            hasAppWindow || WindowPresentation.shared.hasPendingRequest ? .regular : .accessory
        guard NSApp.activationPolicy() != policy else { return }
        NSApp.setActivationPolicy(policy)
        if policy == .regular { NSApp.activate() }
    }

    /// Files dropped on the Dock icon / "Open With" go to the signing queue (MAC-03).
    func application(_ application: NSApplication, open urls: [URL]) {
        queueForSigning(urls)
    }

    /// Finder Quick Actions / Services pass file URLs without starting a signing operation.
    @objc func signDocuments(_ pasteboard: NSPasteboard, userData: String?,
                             error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        guard !urls.isEmpty else { return }
        queueForSigning(urls)
    }

    private func queueForSigning(_ urls: [URL]) {
        model.addFiles(urls)
        AppPreferencesStore.defaults.set(MainWindowView.Section.sign.rawValue, forKey: "mainSection")
        // Allow the menu-bar scene to install its notification receiver on a cold launch.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            NotificationCenter.default.post(name: .showInsertedCard, object: nil)
        }
    }
}

extension Notification.Name {
    static let showInsertedCard = Notification.Name("showInsertedCard")
}

private struct MenuBarIcon: View {
    @Environment(\.openWindow) private var openWindow
    let connected: Bool
    let label: String

    var body: some View {
        Image(nsImage: StatusIcon.image(connected: connected))
            .accessibilityLabel(label)
            .help(label)
            .onReceive(NotificationCenter.default.publisher(for: .showInsertedCard)) { _ in
                WindowPresentation.shared.present(.main) { openWindow(id: "main") }
            }
    }
}

private struct SettingsMenuCommand: View {
    @Environment(\.openSettings) private var openSettings
    var body: some View {
        Button(L10n.text(.ui_settings)) {
            WindowPresentation.shared.present(.settings) { openSettings() }
        }.keyboardShortcut(",", modifiers: .command)
    }
}
