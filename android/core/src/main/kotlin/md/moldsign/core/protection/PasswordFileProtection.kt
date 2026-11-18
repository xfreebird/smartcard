package md.moldsign.core.protection

import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

/** MoldSign Desktop password AES compatibility. CBC has no integrity protection. */
object PasswordFileProtection {
    const val MAXIMUM_SIZE = 64 * 1024 * 1024 - 128
    const val SUFFIX = ".symmetric.p7m"
    val keySizes = listOf(128, 192, 256)
    private val random = SecureRandom()
    private fun marker(bits: Int) = MessageDigest.getInstance("SHA-512").digest(bits.toString().toByteArray(Charsets.US_ASCII))

    fun encrypt(plaintext: ByteArray, password: CharArray, keySize: Int = 256): ByteArray {
        require(keySize in keySizes) { "Unsupported AES key size." }
        require(password.isNotEmpty()) { "Enter a password." }
        require(plaintext.size <= MAXIMUM_SIZE) { "Choose a file smaller than 64 MB." }
        val salt = ByteArray(16).also(random::nextBytes)
        salt[1] = 0xff.toByte() // Force the vendor ASN.1 parser into its AES fallback; 120 random salt bits.
        val iv = ByteArray(16).also(random::nextBytes)
        return salt + iv + marker(keySize) + crypt(plaintext, password, salt, iv, keySize, Cipher.ENCRYPT_MODE)
    }
    fun decrypt(envelope: ByteArray, password: CharArray): ByteArray {
        require(envelope.size <= MAXIMUM_SIZE + 8192) { "Choose a file smaller than 64 MB." }
        if(envelope.size < 112 || (envelope.size-96)%16!=0) return LegacyPasswordProtection.decrypt(envelope,password)
        val bits = keySize(envelope)
            ?: return LegacyPasswordProtection.decrypt(envelope,password)
        return crypt(envelope.copyOfRange(96, envelope.size), password,
            envelope.copyOfRange(0, 16), envelope.copyOfRange(16, 32), bits, Cipher.DECRYPT_MODE)
    }
    internal fun keySize(prefix: ByteArray): Int? {
        if (prefix.size < 96) return null
        val tag = prefix.copyOfRange(32, 96)
        return keySizes.firstOrNull { MessageDigest.isEqual(marker(it), tag) }
    }

    private fun crypt(input: ByteArray, password: CharArray, salt: ByteArray, iv: ByteArray, bits: Int, mode: Int): ByteArray {
        val key = derive(password, salt, bits / 8)
        try {
            return Cipher.getInstance("AES/CBC/PKCS5Padding").run {
                init(mode, SecretKeySpec(key, "AES"), IvParameterSpec(iv)); doFinal(input)
            }
        } catch (e: java.security.GeneralSecurityException) {
            throw IllegalArgumentException("Unable to decrypt. Check the password and the file.")
        } finally { key.fill(0) }
    }
    private fun derive(password: CharArray, salt: ByteArray, length: Int): ByteArray {
        require(password.size < 2048) { "Password is too long." }
        val p = if (password.isEmpty()) ByteArray(0) else ByteArray((password.size + 1) * 2)
        password.forEachIndexed { index, c -> p[index*2] = (c.code ushr 8).toByte(); p[index*2+1] = c.code.toByte() }
        val expanded = if (p.isEmpty()) 0 else 64 * ((p.size + 63) / 64)
        val material = ByteArray(128 + expanded)
        material.fill(1, 0, 64)
        for (i in 0 until 64) material[64+i] = salt[i % salt.size]
        for (i in 0 until expanded) material[128+i] = p[i % p.size]
        val digest = MessageDigest.getInstance("SHA-256")
        var a = digest.digest(material)
        try {
            repeat(65536) { val next = digest.digest(a); a.fill(0); a = next }
            return a.copyOf(length)
        } finally { a.fill(0); p.fill(0); material.fill(0) }
    }
}
