#if !APP_STORE
import AppKit
import SwiftUI

/// Standalone desktop distribution only. No executable is downloaded or installed by the app.
@MainActor
final class AppUpdateChecker {
    static let shared = AppUpdateChecker()
    private var checking = false
    private var periodic: Task<Void, Never>?

    func start() {
        guard periodic == nil else { return }
        periodic = Task { [weak self] in
            while !Task.isCancelled {
                await self?.check(automatic: true)
                do { try await Task.sleep(for: .seconds(24 * 60 * 60)) } catch { return }
            }
        }
    }
    private let defaults = AppPreferencesStore.defaults

    func check(automatic: Bool) async {
        guard !checking, !defaults.bool(forKey: "demoModeEnabled"),
              ProcessInfo.processInfo.environment["MSIGN_DEMO_CARDS"] == nil,
              ProcessInfo.processInfo.environment["MSIGN_QA_NO_HARDWARE"] != "1" else { return }
        let last = defaults.object(forKey: "lastUpdateCheck") as? Date
        if automatic, let last, Date().timeIntervalSince(last) < 7 * 24 * 60 * 60 { return }
        checking = true
        defaults.set(Date(), forKey: "lastUpdateCheck")
        defer { checking = false }
        do {
            var request = URLRequest(url: URL(string: "https://esemnbun.md/updates/macos.json")!)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                  data.count <= 16_384 else { throw URLError(.badServerResponse) }
            let manifest = try JSONDecoder().decode(UpdateManifest.self, from: data)
            guard manifest.isValid else { throw URLError(.cannotParseResponse) }
            let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
            if manifest.isNewer(than: current), let url = URL(string: manifest.downloadURL) {
                NSWorkspace.shared.open(url)
            } else if !automatic { show(L10n.text(.update_current)) }
        } catch {
            if !automatic { show(L10n.text(.update_failed)) }
        }
    }

    private func show(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "eSemnBun"
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

struct UpdateMenuCommand: View {
    var body: some View {
        Button(L10n.text(.update_check)) { Task { await AppUpdateChecker.shared.check(automatic: false) } }
    }
}
#endif
