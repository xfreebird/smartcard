import Foundation
import CryptoKit

/// Public certificate metadata for saved PIN accounts, independent of reader/NFC transport.
/// PIN values remain exclusively in PinVault. Certificate bytes allow exact matching before VERIFY.
struct SavedCardIdentityStore {
    private let defaults: UserDefaults
    private let key = "savedPINCardCertificates"

    init(defaults: UserDefaults) { self.defaults = defaults }

    func certificates(hasSavedPIN: (String) -> Bool) -> [Data] {
        records.compactMap { account, der in
            guard Self.account(for: der) == account, hasSavedPIN(account) else { return nil }
            return der
        }
    }

    func remember(_ certificate: Data) {
        guard !certificate.isEmpty else { return }
        var next = records
        next[Self.account(for: certificate)] = certificate
        defaults.set(next, forKey: key)
    }

    func remove(account: String) {
        var next = records
        next.removeValue(forKey: account)
        defaults.set(next, forKey: key)
    }

    private var records: [String: Data] { defaults.dictionary(forKey: key) as? [String: Data] ?? [:] }
    static func account(for certificate: Data) -> String {
        Insecure.SHA1.hash(data: certificate).map { String(format: "%02x", $0) }.joined()
    }
}
