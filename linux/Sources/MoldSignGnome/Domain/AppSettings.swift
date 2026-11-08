import Foundation

struct AppSettings: Codable, Equatable {
    /// MoldSign Server replica on 127.0.0.1:18480 / localhost.cts.md:18443 (LNX-11).
    var agentApprovalEnabled = false
    var browserStampsEnabled = false
    var bridgeEnabled = true
    var legacyDesktopClientEnabled = false
    /// Keep running (bridge on) after the window is closed (LNX-12).
    var runInBackground = true
    var showOnCardInsertion = false
    var launchAtLogin = false
    /// First-run onboarding (docs/10 §4.7): shown until any dismissal completes it.
    var onboardingCompleted = false
    var theme = "system"
    var language = "system"

    private enum CodingKeys: String, CodingKey {
        case agentApprovalEnabled, browserStampsEnabled, bridgeEnabled, legacyDesktopClientEnabled, runInBackground, showOnCardInsertion, launchAtLogin, onboardingCompleted, theme, language
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        agentApprovalEnabled = try values.decodeIfPresent(Bool.self, forKey: .agentApprovalEnabled) ?? false
        browserStampsEnabled = try values.decodeIfPresent(Bool.self, forKey: .browserStampsEnabled) ?? false
        bridgeEnabled = try values.decodeIfPresent(Bool.self, forKey: .bridgeEnabled) ?? true
        legacyDesktopClientEnabled = try values.decodeIfPresent(Bool.self, forKey: .legacyDesktopClientEnabled) ?? false
        runInBackground = try values.decodeIfPresent(Bool.self, forKey: .runInBackground) ?? true
        showOnCardInsertion = try values.decodeIfPresent(Bool.self, forKey: .showOnCardInsertion) ?? false
        launchAtLogin = try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        onboardingCompleted = try values.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        theme = try values.decodeIfPresent(String.self, forKey: .theme) ?? "system"
        language = try values.decodeIfPresent(String.self, forKey: .language) ?? "system"
    }
}
