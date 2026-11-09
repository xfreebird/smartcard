import UIKit

/// Home Screen / App Library actions share the Siri navigation and file-picker path.
@MainActor
enum HomeScreenQuickActions {
    private enum Action: String, CaseIterable {
        case verify = "md.esemnbun.ios.verify-pdf"
        case prepareSigning = "md.esemnbun.ios.prepare-signing"
        case documents = "md.esemnbun.ios.documents"

        var title: String {
            switch self {
            case .verify: L10n.text(.shortcut_verify_pdf)
            case .prepareSigning: L10n.text(.shortcut_prepare_short)
            case .documents: L10n.text(.shortcut_open_documents)
            }
        }
        var symbol: String {
            switch self {
            case .verify: "checkmark.seal"
            case .prepareSigning: "signature"
            case .documents: "folder"
            }
        }
    }

    /// Refresh on launch and backgrounding so labels follow the app's language selection.
    static func refresh() {
        UIApplication.shared.shortcutItems = Action.allCases.map {
            UIApplicationShortcutItem(type: $0.rawValue, localizedTitle: $0.title,
                                      localizedSubtitle: nil,
                                      icon: UIApplicationShortcutIcon(systemImageName: $0.symbol),
                                      userInfo: nil)
        }
    }

    @discardableResult
    static func handle(_ item: UIApplicationShortcutItem) -> Bool {
        guard let action = Action(rawValue: item.type) else { return false }
        switch action {
        case .verify: ShortcutNavigation.shared.choosePDF(for: .verify)
        case .prepareSigning: ShortcutNavigation.shared.choosePDF(for: .prepareSigning)
        case .documents: ShortcutNavigation.shared.openDocuments()
        }
        return true
    }
}

@MainActor
final class QuickActionsAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = connectingSceneSession.configuration
        configuration.delegateClass = QuickActionsSceneDelegate.self
        return configuration
    }
}

/// SwiftUI owns the window; this delegate only forwards quick-action lifecycle callbacks.
@MainActor
final class QuickActionsSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let item = connectionOptions.shortcutItem {
            // ShortcutNavigation retains this request until RootTabView is ready on cold launch.
            HomeScreenQuickActions.handle(item)
        }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(HomeScreenQuickActions.handle(shortcutItem))
    }
}
