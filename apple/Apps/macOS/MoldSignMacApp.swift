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
            MenuBarIcon(status: appDelegate.model.status)
        }
        .menuBarExtraStyle(.window)

        Window("MoldSign", id: "main") {
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
    }

    /// Files dropped on the Dock icon / "Open With" go to the signing queue (MAC-03).
    func application(_ application: NSApplication, open urls: [URL]) {
        model.addFiles(urls)
    }
}

private struct MenuBarIcon: View {
    let status: ReaderStatus

    var body: some View {
        Image(systemName: status.menuBarSymbol)
            .opacity(status == .noReader || status == .unavailable ? 0.5 : 1)
            .accessibilityLabel(status.title)
    }
}
