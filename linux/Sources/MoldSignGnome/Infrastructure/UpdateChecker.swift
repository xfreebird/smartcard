import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Checks the direct-download feed; update installation always remains an explicit website action.
actor UpdateChecker {
    struct Manifest: Decodable { let version: String; let downloadURL: URL }
    enum Result { case current, available(URL), failed, skipped }
    typealias Fetch = @Sendable (URLRequest) async throws -> (Data, URLResponse)
    static let feed = URL(string: "https://esemnbun.md/updates/linux.json")!
    private let stamp: URL
    private let fetch: Fetch
    private let installedVersion: @Sendable () -> String
    private var checking = false
    /// Package metadata follows the marketing version supplied by the release packager.
    /// A source-tree run falls back to the development version.
    static var currentVersion: String {
        let executable = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let prefix = executable.deletingLastPathComponent().deletingLastPathComponent()
        let metadata = "share/metainfo/md.moldsign.MoldSign.metainfo.xml"
        let candidates = [prefix.appendingPathComponent(metadata), URL(fileURLWithPath: "/app/" + metadata),
                          URL(fileURLWithPath: "/usr/" + metadata)]
        let expression = try? NSRegularExpression(pattern: #"<release\s+version="([0-9.]+)""#)
        for url in candidates {
            guard let source = try? String(contentsOf: url, encoding: .utf8),
                  let match = expression?.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)),
                  let range = Range(match.range(at: 1), in: source) else { continue }
            let version = String(source[range])
            if parts(version) != nil { return version }
        }
        return "0.2.0"
    }

    init(stamp: URL = Store.settingsURL.deletingLastPathComponent().appendingPathComponent("update-check.txt"),
         installedVersion: @escaping @Sendable () -> String = { UpdateChecker.currentVersion },
         fetch: @escaping Fetch = { try await URLSession.shared.data(for: $0) }) {
        self.stamp = stamp
        self.installedVersion = installedVersion
        self.fetch = fetch
    }

    private static func parts(_ value: String) -> [Int]? {
        let items = value.split(separator: ".", omittingEmptySubsequences: false)
        guard items.count == 3, items.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else { return nil }
        let values = items.compactMap { Int($0) }
        return values.count == 3 ? values : nil
    }

    static func isNewer(_ candidate: String, than installed: String) -> Bool {
        guard let latest = parts(candidate), let current = parts(installed) else { return false }
        return current.lexicographicallyPrecedes(latest)
    }

    func check(automatic: Bool, now: Date = Date()) async -> Result {
        guard !checking else { return .skipped }
        if automatic, let contents = try? String(contentsOf: stamp, encoding: .utf8),
           let interval = TimeInterval(contents), now.timeIntervalSince1970 - interval < 7 * 24 * 3600 { return .skipped }
        checking = true
        defer { checking = false }
        do {
            try FileManager.default.createDirectory(at: stamp.deletingLastPathComponent(), withIntermediateDirectories: true)
            try String(now.timeIntervalSince1970).write(to: stamp, atomically: true, encoding: .utf8)
            var request = URLRequest(url: Self.feed)
            request.timeoutInterval = 15
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await fetch(request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return .failed }
            let manifest = try JSONDecoder().decode(Manifest.self, from: data)
            guard Self.parts(manifest.version) != nil, manifest.downloadURL.scheme == "https", manifest.downloadURL.host == "esemnbun.md", manifest.downloadURL.user == nil, manifest.downloadURL.password == nil else { return .failed }
            return Self.isNewer(manifest.version, than: installedVersion()) ? .available(manifest.downloadURL) : .current
        } catch { return .failed }
    }
}
