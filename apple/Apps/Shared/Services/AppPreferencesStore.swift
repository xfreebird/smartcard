import Foundation

/// A dedicated Debug domain keeps screenshot and startup probes away from the user's preferences.
enum AppPreferencesStore {
    static let defaults: UserDefaults = {
        #if DEBUG
        if let suite = ProcessInfo.processInfo.environment["MSIGN_DEMO_PREFERENCES_SUITE"],
           suite.hasPrefix("md.esemnbun.qa."), let isolated = UserDefaults(suiteName: suite) {
            return isolated
        }
        #endif
        return .standard
    }()
}
