import Foundation

protocol LaunchStateStoring {
    var hasPresentedMainWindow: Bool { get }
    func recordMainWindowPresentation()
}

/// Background activation is a preference for subsequent launches, never first-run onboarding.
final class ActivationPolicy {
    enum Destination: Equatable { case mainWindow, background }
    private let store: any LaunchStateStoring
    private var hasPresented: Bool

    init(store: any LaunchStateStoring) {
        self.store = store
        self.hasPresented = store.hasPresentedMainWindow
    }

    func destination(backgroundRequested: Bool, backgroundAllowed: Bool) -> Destination {
        backgroundRequested && backgroundAllowed && hasPresented ? .background : .mainWindow
    }

    /// Called after GTK maps the window. A failed start must not consume the first-run presentation.
    func mainWindowDidPresent() {
        guard !hasPresented else { return }
        store.recordMainWindowPresentation()
        hasPresented = true
    }
}
