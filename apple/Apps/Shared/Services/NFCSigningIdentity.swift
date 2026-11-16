import Foundation

/// Pins the exact certificate for one NFC batch before any PIN command. A new card can bind once;
/// a remembered card or subsequent document must match, without replacing the original identity.
final class NFCSigningIdentity: @unchecked Sendable {
    private let lock = NSLock()
    private var certificate: Data?
    init(expectedCertificate: Data?) { certificate = expectedCertificate }
    var certificateDER: Data? { lock.lock(); defer { lock.unlock() }; return certificate }
    func bind(_ candidate: Data) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if let certificate { return certificate == candidate }
        certificate = candidate
        return true
    }
}
