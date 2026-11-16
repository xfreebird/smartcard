import Foundation

/// Development diagnostics contain operation/status metadata only: never APDU bodies, card IDs,
/// certificate contents, PINs, file names, error descriptions or session keys.
final class NFCSessionDiagnostics: @unchecked Sendable {
    private let lock = NSLock()
    private let id = UUID().uuidString
    private let purpose: String
    private let directory: URL?
    private var events: [[String: String]] = []

    init(purpose: String, directory: URL? = nil) {
        self.purpose = purpose
        #if DEBUG
        self.directory = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("NFCDiagnostics", isDirectory: true)
        #else
        self.directory = directory
        #endif
    }

    func record(_ event: String, instruction: UInt8? = nil, secure: Bool? = nil,
                responseBytes: Int? = nil, status: UInt16? = nil, error: Error? = nil) {
        guard let directory else { return }
        var item = ["event": event, "time": ISO8601DateFormatter().string(from: Date())]
        if let instruction { item["instruction"] = String(format: "%02X", instruction) }
        if let secure { item["secure"] = String(secure) }
        if let responseBytes { item["responseBytes"] = String(responseBytes) }
        if let status { item["status"] = String(format: "%04X", status) }
        if let error {
            let ns = error as NSError
            item["errorDomain"] = ns.domain
            item["errorCode"] = String(ns.code)
            if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError {
                item["underlyingDomain"] = underlying.domain
                item["underlyingCode"] = String(underlying.code)
            }
        }
        lock.lock(); defer { lock.unlock() }
        guard events.count < 300 else { return }
        events.append(item)
        let report: [String: Any] = ["id": id, "purpose": purpose, "events": events,
                                    "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "test",
                                    "build": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "test"]
        guard let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: directory.appendingPathComponent("nfc-\(id).json"), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
