import Foundation

struct AppSettings: Codable, Equatable {
    /// MoldSign Server replica on 127.0.0.1:18480 / localhost.cts.md:18443 (LNX-11).
    var bridgeEnabled = true
    /// Keep running (bridge on) after the window is closed (LNX-12).
    var runInBackground = true
    var showOnCardInsertion = false
    var launchAtLogin = false
    var theme = "system"
    var language = "system"

    private enum CodingKeys: String, CodingKey {
        case bridgeEnabled, runInBackground, showOnCardInsertion, launchAtLogin, theme, language
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bridgeEnabled = try values.decodeIfPresent(Bool.self, forKey: .bridgeEnabled) ?? true
        runInBackground = try values.decodeIfPresent(Bool.self, forKey: .runInBackground) ?? true
        showOnCardInsertion = try values.decodeIfPresent(Bool.self, forKey: .showOnCardInsertion) ?? false
        launchAtLogin = try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        theme = try values.decodeIfPresent(String.self, forKey: .theme) ?? "system"
        language = try values.decodeIfPresent(String.self, forKey: .language) ?? "system"
    }
}
