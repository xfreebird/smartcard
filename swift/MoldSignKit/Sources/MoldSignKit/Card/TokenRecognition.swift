import Foundation

/// USB signing tokens that the vendor suite supports and we recognize by ATR (Phase TOK, experimental).
///
/// Recognition only: no token driver exists yet (TOK-06…). With `SigningService.experimentalTokens` on, a
/// recognized token is reported as `UnsupportedTokenError` instead of being sent IAS/ECC commands. With it
/// off (the default) nothing changes. The table mirrors `spec/tokens/token-families.json`; the ATRs come
/// from the token modules shipped with MoldSign Desktop Suite 2.4.12 and are still unconfirmed on a real token.
public enum TokenFamily: String, CaseIterable, Sendable {
    case ePass2003 = "epass2003"
    case safeNetJava = "safenet-etoken-java"
    case idPrime = "idprime"

    /// Product name for the UI (not translated).
    public var displayName: String {
        switch self {
        case .ePass2003: return "Feitian ePass2003"
        case .safeNetJava: return "SafeNet eToken"
        case .idPrime: return "SafeNet IDPrime"
        }
    }
}

/// An ATR with a mask: a candidate of the same length matches when `(candidate & mask) == (atr & mask)`.
public struct ATRPattern: Equatable, Sendable {
    public let atr: Data
    public let mask: Data

    public init(atr: String, mask: String) {
        self.atr = Data(hex: atr)
        self.mask = Data(hex: mask)
    }

    public func matches(_ candidate: Data) -> Bool {
        guard candidate.count == atr.count, mask.count == atr.count else { return false }
        return zip(zip(candidate, atr), mask).allSatisfy { bytes, mask in bytes.0 & mask == bytes.1 & mask }
    }
}

public enum TokenRecognizer {
    /// Order matters only if two patterns overlap (none do today). Keep in sync with the spec file.
    public static let patterns: [(family: TokenFamily, pattern: ATRPattern)] = [
        (.ePass2003, ATRPattern(atr: "3B9F958131FE9F006646530500000071DF000000000000",
                                mask: "FFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFFFFFFFF00")),
        (.safeNetJava, ATRPattern(atr: "3BD518008131FE7D8073C82110F4", mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.safeNetJava, ATRPattern(atr: "3BD5180081313A7D8073C8211030", mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.safeNetJava, ATRPattern(atr: "3BD518008131FE7D68BF81AA4547", mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.safeNetJava, ATRPattern(atr: "3BD5180081313A7D68BF81AA4583", mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.safeNetJava, ATRPattern(atr: "3BD518008131FE7DDE2D8E7400F7", mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.safeNetJava, ATRPattern(atr: "3BD5180081313A7DDE2D8E740033", mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.safeNetJava, ATRPattern(atr: "3BD518008131FE7D9DAB4639D661", mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.safeNetJava, ATRPattern(atr: "3BD5180081313A7D9DAB4639D6A5", mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.idPrime, ATRPattern(atr: "3BFF9600008131FE4380318065B00000000012917882900069",
                              mask: "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (.idPrime, ATRPattern(atr: "3BFF0000008131004380318065B00000000012021082900000",
                              mask: "FFFF00FFFFFFFF00FFFFFFFFFFFF00000000FFFFFFFFFFFF00")),
    ]

    /// The token family for this ATR, or nil (an eID card, another card, or no ATR).
    public static func family(atr: Data?) -> TokenFamily? {
        guard let atr, !atr.isEmpty else { return nil }
        return patterns.first { $0.pattern.matches(atr) }?.family
    }
}

/// A recognized USB token in a reader. Raised before any APDU reaches it; signing with it is not available yet.
public struct UnsupportedTokenError: Error, LocalizedError, Equatable {
    public let family: TokenFamily
    public init(family: TokenFamily) { self.family = family }
    public var errorDescription: String? { "\(family.displayName) recognized; signing with USB tokens is not available yet" }
}
