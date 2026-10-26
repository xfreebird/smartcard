import Foundation

/// Small JSON files under the XDG base directories (no GSettings schema to install, so the binary
/// runs straight from `.build/`). Inside Flatpak these resolve to `~/.var/app/md.moldsign.MoldSign/…`.
enum Store {
    struct Settings: Codable, Equatable {
        /// MoldSign Server replica on 127.0.0.1:18480 / localhost.cts.md:18443 (LNX-11).
        var bridgeEnabled = true
        /// Keep running (bridge on) after the window is closed (LNX-12).
        var runInBackground = true
    }

    /// `$XDG_CONFIG_HOME/moldsign/settings.json`
    static var settingsURL: URL {
        URL(fileURLWithPath: userConfigDir).appendingPathComponent("moldsign/settings.json")
    }

    /// `$XDG_DATA_HOME/moldsign/activity.json`
    static var activityURL: URL {
        URL(fileURLWithPath: userDataDir).appendingPathComponent("moldsign/activity.json")
    }

    static var bridgeIdentityURL: URL {
        URL(fileURLWithPath: userDataDir).appendingPathComponent("moldsign/localhost.p12")
    }

    static let activityLimit = 100

    static func loadSettings() -> Settings {
        load(Settings.self, from: settingsURL) ?? Settings()
    }

    static func save(_ settings: Settings) {
        write(settings, to: settingsURL)
    }

    static func loadActivity() -> [ActivityItem] {
        load([ActivityItem].self, from: activityURL) ?? []
    }

    static func save(_ activity: [ActivityItem]) {
        write(Array(activity.prefix(activityLimit)), to: activityURL)
    }

    private static func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }

    private static func write<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
                                                 attributes: [.posixPermissions: 0o700])
        try? data.write(to: url, options: .atomic)
    }
}
