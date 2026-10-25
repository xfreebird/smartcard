import Foundation
#if canImport(Security) && !MOLDSIGN_PORTABLE
import Security
#else
import CPCSC
#endif

/// RSA PKCS#1 v1.5 (SHA-256 / SHA-1) verification with a certificate's public key.
/// Security.framework on Apple; OpenSSL (C shim) on Linux and in MOLDSIGN_PORTABLE test builds (LNX-03).
enum RSAVerifier {
    /// PKCS#1 v1.5 over a precomputed digest (SHA-256 by default; SHA-1 for XAdES signed "as requested", R-11).
    static func verify(certDER: Data, digest: Data, signature: Data,
                       algorithm: XAdESSigner.DigestAlgorithm = .sha256) -> Bool {
        #if canImport(Security) && !MOLDSIGN_PORTABLE
        guard let cert = SecCertificateCreateWithData(nil, certDER as CFData),
              let key = SecCertificateCopyKey(cert) else { return false }
        var error: Unmanaged<CFError>?
        let alg: SecKeyAlgorithm = algorithm == .sha1 ? .rsaSignatureDigestPKCS1v15SHA1 : .rsaSignatureDigestPKCS1v15SHA256
        return SecKeyVerifySignature(key, alg, digest as CFData, signature as CFData, &error)
        #else
        guard digest.count == (algorithm == .sha1 ? 20 : 32) else { return false }
        return certDER.withUnsafeBytes { c in
            digest.withUnsafeBytes { d in
                signature.withUnsafeBytes { s in
                    c_rsa_verify_digest(c.bindMemory(to: UInt8.self).baseAddress, certDER.count,
                                        d.bindMemory(to: UInt8.self).baseAddress, digest.count,
                                        s.bindMemory(to: UInt8.self).baseAddress, signature.count) == 1
                }
            }
        }
        #endif
    }
}
