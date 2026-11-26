/// Why the app wants its main window on screen.
enum MainWindowTrigger: Equatable {
    /// Menus, the Dock, shortcuts, Services, opened files and launch arguments.
    case userAction
    /// A reader or card insertion reported by the helper or by the running app's own monitor.
    case cardInsertion
}

/// What AppKit reports about the registered main window when a request arrives.
struct MainWindowState: Equatable {
    /// `NSWindow.isVisible`: ordered into the window list, on any Space.
    var isOrderedIn: Bool
    var isMiniaturized: Bool
    /// `NSApplication.isHidden` (Hide eSemnBun / Command-H).
    var applicationHidden: Bool

    /// The user can already see the window without the app doing anything.
    var isShowing: Bool { isOrderedIn && !isMiniaturized && !applicationHidden }
}

/// Insertion updates an open window in place: no activation, no reordering and no focus change.
/// Every explicit request keeps bringing the window forward.
enum MainWindowPresentationPolicy {
    enum Action: Equatable {
        /// Open or reuse the window, unhide/deminiaturize it, activate the app and make the window key.
        case bringForward
        /// Leave windows and activation alone; the observed model refreshes the visible content.
        case updateContentOnly
    }

    static func action(for trigger: MainWindowTrigger, window: MainWindowState?) -> Action {
        guard trigger == .cardInsertion, let window, window.isShowing else { return .bringForward }
        return .updateContentOnly
    }
}
