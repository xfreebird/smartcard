import Foundation

struct JSONMonitoringConsentStore: MonitoringConsentStoring {
    let url: URL
    init(url: URL = Store.settingsURL.deletingLastPathComponent().appendingPathComponent("diagnostics-consent.json")) {
        self.url = url
    }
    func load() -> MonitoringConsent? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MonitoringConsent.self, from: data)
    }
    func save(_ consent: MonitoringConsent) throws {
        let data = try JSONEncoder().encode(consent)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try data.write(to: url, options: .atomic)
    }
}
