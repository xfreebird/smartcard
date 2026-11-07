import Foundation
import LocalAuthentication
import Security

/// Stored PIN, keyed by the card certificate SHA-1 (docs/09 §3.5, MAC-04, IOS-05, SEC-05).
///
/// Every read is gated by the device owner (Touch ID / Face ID / password) through `LAContext`.
/// Signed builds also get `SecAccessControl(.userPresence)` on a data-protection keychain item.
/// DEBUG unsigned dev builds lack the keychain entitlement (-34018), so they fall back to a plain item, still gated by LAContext.
/// Release reads only the protected store; legacy records require manual PIN entry and saving again.
protocol PinStoring {
    func savedAccounts() -> [String]
    func hasPIN(certID: String) -> Bool
    func save(_ pin: String, certID: String) throws
    func load(certID: String, reason: String) async -> String?
    func delete(certID: String)
}

struct PinVault: PinStoring {
    private let service = "md.moldsign.pin"
    // Production must not discover or release legacy records without a Keychain presence ACL.
    private var readableStores: [Bool] {
        #if DEBUG
        [true, false]
        #else
        [true]
        #endif
    }

    /// Metadata only, including cards that are currently disconnected.
    func savedAccounts() -> [String] {
        var accounts = Set<String>()
        for dataProtection in readableStores {
            var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service, kSecReturnAttributes as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll]
            if dataProtection { query[kSecUseDataProtectionKeychain as String] = true }
            let silent = LAContext()
            silent.interactionNotAllowed = true
            query[kSecUseAuthenticationContext as String] = silent
            var result: CFTypeRef?
            if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
               let items = result as? [[String: Any]] {
                for item in items {
                    if let account = item[kSecAttrAccount as String] as? String { accounts.insert(account) }
                }
            }
        }
        return accounts.sorted()
    }

    func hasPIN(certID: String) -> Bool {
        let silent = LAContext()
        silent.interactionNotAllowed = true
        return readableStores.contains { dataProtection in
            var query = baseQuery(certID, dataProtection: dataProtection)
            query[kSecUseAuthenticationContext as String] = silent
            let status = SecItemCopyMatching(query as CFDictionary, nil)
            return status == errSecSuccess || status == errSecInteractionNotAllowed
        }
    }

    func save(_ pin: String, certID: String) throws {
        delete(certID: certID)
        if let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, nil) {
            var item = baseQuery(certID, dataProtection: true)
            item[kSecValueData as String] = Data(pin.utf8)
            item[kSecAttrAccessControl as String] = access
            let status = SecItemAdd(item as CFDictionary, nil)
            if status == errSecSuccess { return }
            #if DEBUG
            guard status == errSecMissingEntitlement else { throw VaultError.keychain(status) }
            #else
            throw VaultError.keychain(status)
            #endif
        }
        #if DEBUG
        var item = baseQuery(certID, dataProtection: false)
        item[kSecValueData as String] = Data(pin.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw VaultError.keychain(status) }
        #else
        throw VaultError.keychain(errSecParam)
        #endif
    }

    /// Asks for the device owner first, then reads the PIN. nil when none is stored or the user cancels.
    func load(certID: String, reason: String) async -> String? {
        guard hasPIN(certID: certID) else { return nil }
        let context = LAContext()
        context.localizedCancelTitle = L10n.text(.ui_cancel)
        guard (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) == true else {
            return nil
        }
        for dataProtection in readableStores {
            var query = baseQuery(certID, dataProtection: dataProtection)
            query[kSecReturnData as String] = true
            query[kSecUseAuthenticationContext as String] = context
            var out: CFTypeRef?
            if SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess, let data = out as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }

    func delete(certID: String) {
        SecItemDelete(baseQuery(certID, dataProtection: true) as CFDictionary)
        SecItemDelete(baseQuery(certID, dataProtection: false) as CFDictionary)
    }

    private func baseQuery(_ certID: String, dataProtection: Bool) -> [String: Any] {
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: certID]
        if dataProtection { query[kSecUseDataProtectionKeychain as String] = true }
        return query
    }

    enum VaultError: Error { case keychain(OSStatus) }
}
