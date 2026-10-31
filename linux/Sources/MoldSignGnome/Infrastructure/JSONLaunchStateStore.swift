import Foundation

struct JSONLaunchStateStore: LaunchStateStoring {
    private struct State: Codable { var hasPresentedMainWindow = false }
    let url: URL

    init(url: URL = Store.settingsURL.deletingLastPathComponent().appendingPathComponent("launch-state.json")) {
        self.url = url
    }

    var hasPresentedMainWindow: Bool {
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(State.self, from: data) else { return false }
        return state.hasPresentedMainWindow
    }

    func recordMainWindowPresentation() {
        guard let data = try? JSONEncoder().encode(State(hasPresentedMainWindow: true)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
                                                 attributes: [.posixPermissions: 0o700])
        try? data.write(to: url, options: .atomic)
    }
}
