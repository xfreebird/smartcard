import AppKit

/// Completes explicit menu actions after the popover has closed and SwiftUI has supplied the target window.
@MainActor
final class WindowPresentation {
    enum Destination { case main, settings }
    static let shared = WindowPresentation()

    private weak var mainWindow: NSWindow?
    private weak var settingsWindow: NSWindow?
    private var pending: Destination?

    var hasPendingRequest: Bool { pending != nil }

    func present(_ destination: Destination, open: () -> Void) {
        pending = destination
        NSApp.setActivationPolicy(.regular)
        open()
        DispatchQueue.main.async { [weak self] in self?.finishPendingRequest() }
    }

    func register(_ window: NSWindow?, for destination: Destination) {
        guard let window else { return }
        switch destination {
        case .main: mainWindow = window
        case .settings: settingsWindow = window
        }
        guard pending == destination else { return }
        DispatchQueue.main.async { [weak self] in self?.finishPendingRequest() }
    }

    func unregister(_ window: NSWindow) {
        if mainWindow === window { mainWindow = nil }
        if settingsWindow === window { settingsWindow = nil }
    }

    static func bringForward(_ window: NSWindow) {
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func finishPendingRequest() {
        guard let pending else { return }
        let window = pending == .main ? mainWindow : settingsWindow
        guard let window else { return }
        NSApp.setActivationPolicy(.regular)
        Self.bringForward(window)
        self.pending = nil
    }
}
