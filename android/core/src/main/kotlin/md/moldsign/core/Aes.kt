package md.moldsign.core

import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * AES block primitives over javax.crypto (port of Swift `AES` + the `CPCSC` CommonCrypto shim).
 * Raw modes only: no padding is ever added here; ISO 9797-1 M2 padding is [Iso9797]'s job.
 */
class Aes(key: ByteArray) {
    private val keySpec: SecretKeySpec

    init {
        require(key.size == 16 || key.size == 24 || key.size == 32) { "AES key must be 16/24/32 bytes, got ${key.size}" }
        keySpec = SecretKeySpec(key.copyOf(), "AES")
    }

    /** Single-block AES-ECB encryption. */
    fun ecbEncryptBlock(block: ByteArray): ByteArray {
        require(block.size == BLOCK) { "ECB block must be 16 bytes, got ${block.size}" }
        val c = Cipher.getInstance("AES/ECB/NoPadding")
        c.init(Cipher.ENCRYPT_MODE, keySpec)
        return c.doFinal(block)
    }

    /** AES-CBC encryption without padding; [data] must be a multiple of 16 bytes. */
    fun cbcEncrypt(data: ByteArray, iv: ByteArray): ByteArray = cbc(Cipher.ENCRYPT_MODE, data, iv)

    /** AES-CBC decryption without padding; [data] must be a multiple of 16 bytes. */
    fun cbcDecrypt(data: ByteArray, iv: ByteArray): ByteArray = cbc(Cipher.DECRYPT_MODE, data, iv)

    private fun cbc(mode: Int, data: ByteArray, iv: ByteArray): ByteArray {
        require(data.size % BLOCK == 0) { "CBC input must be a multiple of 16 bytes, got ${data.size}" }
        require(iv.size == BLOCK) { "IV must be 16 bytes, got ${iv.size}" }
        if (data.isEmpty()) return ByteArray(0)
        val c = Cipher.getInstance("AES/CBC/NoPadding")
        c.init(mode, keySpec, IvParameterSpec(iv))
        return c.doFinal(data)
    }

    companion object {
        const val BLOCK = 16
        val ZERO_IV: ByteArray get() = ByteArray(BLOCK)
    }
}

/** Byte-wise XOR over the shorter length (Swift `AES.xorBytes`). */
fun xorBytes(a: ByteArray, b: ByteArray): ByteArray = ByteArray(minOf(a.size, b.size)) { i -> (a[i].toInt() xor b[i].toInt()).toByte() }
