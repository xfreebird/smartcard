package md.moldsign.core

/**
 * USB signing tokens recognized by ATR (Phase TOK, experimental, off by default). Port of the Swift
 * `TokenRecognition.swift`; the table mirrors `spec/tokens/token-families.json`, whose ATRs come from the token
 * modules of MoldSign Desktop Suite 2.4.12 and are not yet confirmed on a real token. Recognition only: no
 * token driver exists yet, so a recognized token fails with [UnsupportedTokenException] before any APDU.
 */
enum class TokenFamily(val id: String, val displayName: String) {
    EPASS2003("epass2003", "Feitian ePass2003"),
    SAFENET_JAVA("safenet-etoken-java", "SafeNet eToken"),
    IDPRIME("idprime", "SafeNet IDPrime"),
}

/** A candidate of the same length matches when `(candidate & mask) == (atr & mask)` byte by byte. */
class AtrPattern(atrHex: String, maskHex: String) {
    val atr: ByteArray = Hex.decode(atrHex)
    val mask: ByteArray = Hex.decode(maskHex)

    fun matches(candidate: ByteArray): Boolean {
        if (candidate.size != atr.size || mask.size != atr.size) return false
        return candidate.indices.all { i ->
            (candidate[i].toInt() and mask[i].toInt()) == (atr[i].toInt() and mask[i].toInt())
        }
    }
}

object TokenRecognizer {
    private const val EXACT14 = "FFFFFFFFFFFFFFFFFFFFFFFFFFFF"

    /** Keep in sync with the spec file (TokenRecognitionTest compares them). */
    val patterns: List<Pair<TokenFamily, AtrPattern>> = listOf(
        TokenFamily.EPASS2003 to AtrPattern("3B9F958131FE9F006646530500000071DF000000000000",
            "FFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFFFFFFFF00"),
        TokenFamily.SAFENET_JAVA to AtrPattern("3BD518008131FE7D8073C82110F4", EXACT14),
        TokenFamily.SAFENET_JAVA to AtrPattern("3BD5180081313A7D8073C8211030", EXACT14),
        TokenFamily.SAFENET_JAVA to AtrPattern("3BD518008131FE7D68BF81AA4547", EXACT14),
        TokenFamily.SAFENET_JAVA to AtrPattern("3BD5180081313A7D68BF81AA4583", EXACT14),
        TokenFamily.SAFENET_JAVA to AtrPattern("3BD518008131FE7DDE2D8E7400F7", EXACT14),
        TokenFamily.SAFENET_JAVA to AtrPattern("3BD5180081313A7DDE2D8E740033", EXACT14),
        TokenFamily.SAFENET_JAVA to AtrPattern("3BD518008131FE7D9DAB4639D661", EXACT14),
        TokenFamily.SAFENET_JAVA to AtrPattern("3BD5180081313A7D9DAB4639D6A5", EXACT14),
        TokenFamily.IDPRIME to AtrPattern("3BFF9600008131FE4380318065B00000000012917882900069",
            "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
        TokenFamily.IDPRIME to AtrPattern("3BFF0000008131004380318065B00000000012021082900000",
            "FFFF00FFFFFFFF00FFFFFFFFFFFF00000000FFFFFFFFFFFF00"),
    )

    /** The token family for this ATR, or null (an eID card, another card, or no ATR). */
    fun family(atr: ByteArray?): TokenFamily? {
        if (atr == null || atr.isEmpty()) return null
        return patterns.firstOrNull { it.second.matches(atr) }?.first
    }
}

/**
 * A recognized USB token in the reader; signing with it is not available yet. Not a [CardError] subclass, so
 * the existing exhaustive error handling stays unchanged.
 */
class UnsupportedTokenException(val family: TokenFamily) :
    Exception("${family.displayName} recognized; signing with USB tokens is not available yet")
