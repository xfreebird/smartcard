import SwiftUI
import MoldSignKit
import AppIntents
import CoreSpotlight

/// macOS menu-bar agent (LSUIElement): status icon + popover, main window on demand, Settings (MAC-01, MAC-09).
@main
struct MoldSignMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"

    init() { ESemnBunShortcuts.updateAppShortcutParameters() }

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
            MenuBarIcon(delegate: appDelegate, connected: appDelegate.model.cardConnected, label: appDelegate.model.trayLabel)
        }
        .menuBarExtraStyle(.window)

        Window(L10n.text(.ui_esemnbun), id: "main") {
            MainWindowView()
                .environment(appDelegate.model)
                .appPreferences()
                .frame(minWidth: 860, minHeight: 580)
        }
        .windowToolbarStyle(.unified)
        .defaultLaunchBehavior(WindowPresentation.shared.presentsMainWindowAtLaunch ? .presented : .suppressed)

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
                Button(L10n.text(.ui_help_menu)) {
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
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var readerWindowRequested = false
    let model = AppModel()
    #if !APP_STORE
    private var approvalBroker: AgentApprovalBroker?
    #endif
    private let authPanel = AuthPanelController()

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Participate in the launcher's foreground handoff before the onboarding window opens.
        if WindowPresentation.shared.presentsMainWindowAtLaunch {
            NSApp.setActivationPolicy(.regular)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self
        authPanel.attach(model)
        model.presentInsertedCard = {
            NotificationCenter.default.post(name: .showInsertedCard, object: nil)
        }
        model.start()
        ESemnBunShortcuts.updateAppShortcutParameters()
        DocumentDiscovery.refresh()
        #if !APP_STORE
        approvalBroker = AgentApprovalBroker(model: model)
        approvalBroker?.start()
        #endif
        #if !APP_STORE
        AppUpdateChecker.shared.start()
        #endif
        observeWindows()
        if ShortcutNavigation.shared.request != nil || ProcessInfo.processInfo.arguments.contains("--show-main-window") {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                NotificationCenter.default.post(name: .showInsertedCard, object: nil)
            }
        }
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["MSIGN_DEMO_CARDS"] != nil, env["MSIGN_DEMO_PREVIEW"] != "0", env["MSIGN_DEMO_SETTINGS"] != "1" {
            showDesignPreviews()
        }
        #endif
    }

    #if DEBUG
    /// Design QA with demo cards: the popover can't be opened programmatically, so show it (and the main
    /// window) in plain windows. Debug builds only.
    private var previewWindows: [NSWindow] = []

    private func showDesignPreviews() {
        let environment = ProcessInfo.processInfo.environment
        if environment["MSIGN_DEMO_DARK"] != nil { NSApp.appearance = NSAppearance(named: .darkAqua) }
        // Exercise the production minimum and larger layouts without changing normal window restoration.
        let width = max(860, min(1920, Double(environment["MSIGN_DEMO_WIDTH"] ?? "") ?? 980))
        let height = max(580, min(1200, Double(environment["MSIGN_DEMO_HEIGHT"] ?? "") ?? 700))
        let popover = NSHostingController(rootView: MenuBarPopover().environment(model).appPreferences())
        let main = NSHostingController(rootView: MainWindowView().environment(model).appPreferences().frame(width: width, height: height))
        for (title, controller, origin) in [("Popover preview", popover as NSViewController, NSPoint(x: 60, y: 120)),
                                            ("eSemnBun preview", main as NSViewController, NSPoint(x: 420, y: 80))] {
            let window = NSWindow(contentViewController: controller)
            window.title = title
            window.toolbarStyle = .unified
            window.setFrameOrigin(origin)
            if environment["MSIGN_SCREENSHOT_CAPTURE"] == "1",
               let visibleFrame = NSScreen.main?.visibleFrame {
                // Native sheets and WebKit render only on-screen; keep capture previews in view.
                window.setFrameTopLeftPoint(NSPoint(x: visibleFrame.minX + 40, y: visibleFrame.maxY - 8))
            }
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

    func application(_ application: NSApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
        guard [DocumentDiscovery.activityType, CSSearchableItemActionType].contains(userActivity.activityType) else { return false }
        DocumentDiscovery.resume(userActivity)
        return true
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
        #if APP_STORE
        if urls.contains(URL(string: "esemnbun-reader://inserted")!), !model.demoMode,
           ReaderActivationService().active {
            readerWindowRequested = true
        }
        #endif
        let files = urls.filter(\.isFileURL)
        if !files.isEmpty { queueForSigning(files) }
    }

    /// Finder Quick Actions / Services pass file URLs without starting a signing operation.
    @objc func signDocuments(_ pasteboard: NSPasteboard, userData: String?,
                             error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        guard !urls.isEmpty else { return }
        queueForSigning(urls)
    }

    /// Verification is explicit and read-only; the signing queue and approval gate remain untouched.
    @objc func verifyDocuments(_ pasteboard: NSPasteboard, userData: String?,
                               error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        guard !urls.isEmpty else { return }
        AppPreferencesStore.defaults.set(MainWindowView.Section.verify.rawValue, forKey: "mainSection")
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            NotificationCenter.default.post(name: .showInsertedCard, object: nil)
            await model.verifyFiles(urls)
        }
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
    @ObservedObject var delegate: AppDelegate
    let connected: Bool
    let label: String

    var body: some View {
        Image(nsImage: StatusIcon.image(connected: connected))
            .accessibilityLabel(label)
            .help(label)
            .onChange(of: delegate.readerWindowRequested, initial: true) { _, requested in
                guard requested else { return }
                WindowPresentation.shared.present(.main) { openWindow(id: "main") }
                delegate.readerWindowRequested = false
            }
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
