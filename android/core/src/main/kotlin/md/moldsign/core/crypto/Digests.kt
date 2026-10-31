package md.moldsign.core

import java.security.MessageDigest

object Sha {
    fun sha256(vararg parts: ByteArray): ByteArray = digest("SHA-256", parts)
    fun sha1(vararg parts: ByteArray): ByteArray = digest("SHA-1", parts)

    private fun digest(alg: String, parts: Array<out ByteArray>): ByteArray {
        val md = MessageDigest.getInstance(alg)
        parts.forEach { md.update(it) }
        return md.digest()
    }
}

/** PKCS#1 DigestInfo encodings fed to INTERNAL AUTHENTICATE (the card does raw RSA). */
object DigestInfo {
    /** DER prefix: SEQUENCE { SEQUENCE { OID sha256, NULL }, OCTET STRING (32) }. */
    val SHA256_PREFIX: ByteArray get() = "3031300D060960864801650304020105000420".decodeHex()

    /** DigestInfo(SHA-256) over [message] (hashes it first). */
    fun sha256(message: ByteArray): ByteArray = forSha256Digest(Sha.sha256(message))

    /** DigestInfo(SHA-256) for an already computed 32-byte digest. */
    fun forSha256Digest(digest: ByteArray): ByteArray {
        require(digest.size == 32) { "SHA-256 digest must be 32 bytes, got ${digest.size}" }
        return SHA256_PREFIX + digest
    }
}
