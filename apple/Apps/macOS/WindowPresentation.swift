import AppKit

/// Completes explicit menu actions after the popover has closed and SwiftUI has supplied the target window.
@MainActor
final class WindowPresentation {
    enum Destination { case main, settings, about }
    static let shared = WindowPresentation()

    private weak var mainWindow: NSWindow?
    private weak var settingsWindow: NSWindow?
    private weak var aboutWindow: NSWindow?
    private var pending: Destination?

    var hasPendingRequest: Bool { pending != nil }

    func present(_ destination: Destination, open: @escaping () -> Void) {
        pending = destination
        NSApp.setActivationPolicy(.regular)
        // SwiftUI's Settings action needs an active application even when no app window
        // exists yet. Let the accessory-to-regular transition complete before opening it.
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [weak self] in
            open()
            self?.finishPendingRequest()
        }
    }

    func register(_ window: NSWindow?, for destination: Destination) {
        guard let window else { return }
        switch destination {
        case .main: mainWindow = window
        case .settings: settingsWindow = window
        case .about:
            aboutWindow = window
            window.styleMask.remove([.resizable, .miniaturizable])
            window.standardWindowButton(.zoomButton)?.isEnabled = false
            window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
            window.standardWindowButton(.closeButton)?.isEnabled = true
            window.collectionBehavior.remove(.fullScreenPrimary)
            window.collectionBehavior.insert(.fullScreenNone)
        }
        guard pending == destination else { return }
        DispatchQueue.main.async { [weak self] in self?.finishPendingRequest() }
    }

    func unregister(_ window: NSWindow) {
        if mainWindow === window { mainWindow = nil }
        if settingsWindow === window { settingsWindow = nil }
        if aboutWindow === window { aboutWindow = nil }
    }

    static func bringForward(_ window: NSWindow) {
        NSApp.unhide(nil)
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.orderFrontRegardless()
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        // A menu-bar popover can briefly remain key during its close animation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak window] in
            guard let window, window.isVisible else { return }
            NSRunningApplication.current.activate(options: [.activateAllWindows])
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func finishPendingRequest() {
        guard let pending else { return }
        let window: NSWindow?
        switch pending {
        case .main: window = mainWindow
        case .settings: window = settingsWindow
        case .about: window = aboutWindow
        }
        guard let window else { return }
        NSApp.setActivationPolicy(.regular)
        Self.bringForward(window)
        self.pending = nil
    }
}
