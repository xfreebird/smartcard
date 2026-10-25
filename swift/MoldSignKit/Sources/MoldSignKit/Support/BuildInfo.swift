import Foundation
import CPCSC

/// Which implementations this build uses (Apple frameworks vs the Linux/portable ones).
public enum BuildInfo {
    public static var isPortable: Bool {
        #if MOLDSIGN_PORTABLE
        return true
        #else
        return false
        #endif
    }

    public static var cryptoBackend: String { c_openssl_available() == 1 ? "OpenSSL" : "CommonCrypto/CryptoKit" }
    public static var smartCardStack: String { c_scard_available() == 1 ? "PC/SC" : "CryptoTokenKit" }
}
