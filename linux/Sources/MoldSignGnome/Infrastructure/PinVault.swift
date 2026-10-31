import CLibSecret
import Foundation

/// PIN storage on the freedesktop Secret Service through libsecret (docs/09 §3.5, LNX-10):
/// GNOME Keyring on GNOME, KWallet / KeePassXC elsewhere; in Flatpak via `org.freedesktop.secrets`.
///
/// Keyed by the card certificate's SHA-1 (attribute `cert`), so a different card never receives
/// another card's PIN. Saved only after the card accepted the PIN; deleted on a wrong PIN.
/// Every call blocks on D-Bus: call from a background queue, never the GTK main thread.
///
/// Gate: unlike Touch ID / Windows Hello, the Secret Service has no per-read user-presence check;
/// the login keyring is unlocked with the session. The app therefore always shows a confirmation
/// (consent) dialog before a signature that uses the stored PIN.
/// TODO(LNX-10): optional per-use gate (polkit `auth_self` action, or a dedicated locked collection).
final class PinVault: PINStoring {
    static let schemaName = "md.moldsign.pin"

    private let schema: UnsafeMutablePointer<SecretSchema>

    init() {
        // secret_schema_new() is variadic; build the attribute table for secret_schema_newv() instead.
        let types = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, nil)
        // SECRET_SCHEMA_ATTRIBUTE_STRING == 0, i.e. GINT_TO_POINTER(0) == NULL
        g_hash_table_insert(types, g_strdup("cert"), nil)
        schema = secret_schema_newv(Self.schemaName, SECRET_SCHEMA_NONE, types)
        g_hash_table_unref(types)
    }

    deinit { secret_schema_unref(schema) }

    func save(_ pin: String, certID: String, holder: String) throws {
        var error: UnsafeMutablePointer<GError>?
        let ok = withAttributes(certID) { attrs in
            // nil collection = the default keyring ("login" on GNOME)
            secret_password_storev_sync(schema, attrs, nil, "eSemnBun PIN QSCD — \(holder)", pin, nil, &error)
        }
        if ok == 0 { throw VaultError(message: takeGError(error) ?? "secret_password_storev_sync failed") }
    }

    func load(certID: String) -> PINLookup {
        var error: UnsafeMutablePointer<GError>?
        // Non-pageable copy, wiped by secret_password_free().
        let secret = withAttributes(certID) { attrs in
            secret_password_lookupv_nonpageable_sync(schema, attrs, nil, &error)
        }
        if let message = takeGError(error) { return .unavailable(message) }
        guard let secret else { return .missing }
        defer { secret_password_free(secret) }
        return .found(String(cString: secret))
    }

    func hasPIN(certID: String) -> Bool {
        if case .found = load(certID: certID) { return true }
        return false
    }

    @discardableResult
    func delete(certID: String) -> Bool {
        var error: UnsafeMutablePointer<GError>?
        let removed = withAttributes(certID) { attrs in
            secret_password_clearv_sync(schema, attrs, nil, &error)
        }
        _ = takeGError(error)
        return removed != 0
    }

    /// Clear this application's schema only, including cards that are no longer inserted.
    func deleteAll() -> Bool {
        var error: UnsafeMutablePointer<GError>?
        let attrs = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, g_free)
        defer { g_hash_table_unref(attrs) }
        let removed = secret_password_clearv_sync(schema, attrs, nil, &error)
        let message = takeGError(error)
        return removed != 0 && message == nil
    }

    /// nil when a Secret Service answers; otherwise a user-facing reason.
    func availabilityProblem() -> String? {
        if case .unavailable = load(certID: "0000000000000000000000000000000000000000") {
            return L10n.text(.linux_keyring_unavailable)
        }
        return nil
    }

    private func withAttributes<T>(_ certID: String, _ body: (OpaquePointer?) -> T) -> T {
        let attrs = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, g_free)
        g_hash_table_insert(attrs, g_strdup("cert"), g_strdup(certID.lowercased()))
        defer { g_hash_table_unref(attrs) }
        return body(attrs)
    }

    private func takeGError(_ error: UnsafeMutablePointer<GError>?) -> String? {
        guard let error else { return nil }
        defer { g_error_free(error) }
        return error.pointee.message.map { String(cString: $0) }
    }

    struct VaultError: Error, CustomStringConvertible {
        let message: String
        var description: String { message }
    }
}
