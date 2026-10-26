import SwiftUI
import MoldSignKit

/// macOS menu-bar agent (LSUIElement): status icon + popover, main window on demand, Settings (MAC-01, MAC-09).
@main
struct MoldSignMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopover()
                .environment(appDelegate.model)
        } label: {
            MenuBarIcon(connected: appDelegate.model.cardConnected, label: appDelegate.model.trayLabel)
        }
        .menuBarExtraStyle(.window)

        Window("eSemnBun", id: "main") {
            MainWindowView()
                .environment(appDelegate.model)
                .frame(minWidth: 860, minHeight: 580)
        }
        .defaultLaunchBehavior(.suppressed)

        Settings {
            SettingsView()
                .environment(appDelegate.model)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private let authPanel = AuthPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        authPanel.attach(model)
        model.start()
        observeWindows()
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
        let popover = NSHostingController(rootView: MenuBarPopover().environment(model))
        let main = NSHostingController(rootView: MainWindowView().environment(model).frame(width: 980, height: 700))
        for (title, controller, origin) in [("Popover preview", popover as NSViewController, NSPoint(x: 60, y: 120)),
                                            ("eSemnBun preview", main as NSViewController, NSPoint(x: 420, y: 80))] {
            let window = NSWindow(contentViewController: controller)
            window.title = title
            window.setFrameOrigin(origin)
            window.makeKeyAndOrderFront(nil)
            previewWindows.append(window)
        }
        NSApp.activate()
    }
    #endif

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
        model.addFiles(urls)
    }
}

private struct MenuBarIcon: View {
    let connected: Bool
    let label: String

    var body: some View {
        Image(nsImage: StatusIcon.image(connected: connected))
            .accessibilityLabel(label)
            .help(label)
    }
}
