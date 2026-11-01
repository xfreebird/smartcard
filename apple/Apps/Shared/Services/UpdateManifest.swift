import Foundation

/// Stable release channel. The manifest points to our download page, never an executable URL.
struct UpdateManifest: Decodable {
    let version: String
    let downloadURL: String

    private func components(_ value: String) -> [Int]? {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        let values = parts.compactMap { part -> Int? in
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
            return Int(part)
        }
        return values.count == 3 ? values : nil
    }

    var isValid: Bool {
        guard components(version) != nil, let url = URL(string: downloadURL) else { return false }
        return url.scheme == "https" && url.host == "esemnbun.md" && url.user == nil && url.password == nil
    }

    func isNewer(than current: String) -> Bool {
        guard isValid, let latest = components(version), let installed = components(current) else { return false }
        return installed.lexicographicallyPrecedes(latest)
    }
}
