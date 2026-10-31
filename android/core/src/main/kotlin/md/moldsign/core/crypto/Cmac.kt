package md.moldsign.core

/**
 * AES-CMAC per RFC 4493 / NIST SP 800-38B (full 16-byte tag).
 *
 * Deliberately NOT a line-by-line copy of `cpcsc.c::c_aes256_cmac`: the C version writes
 * `M_last[16]` (out of bounds) for an EMPTY message because it treats `len % 16 == 0` as a full
 * last block of 16 bytes. Here an empty message is one incomplete block (`80 00 … ^ K2`), which
 * yields the NIST tag 028962F6… (see `spec/vectors/card-crypto.json`). Non-empty inputs, the
 * only ones the card protocol produces, give identical results.
 */
object Cmac {
    private const val RB = 0x87

    fun aesCmac(key: ByteArray, message: ByteArray): ByteArray {
        val aes = Aes(key)
        val l = aes.ecbEncryptBlock(ByteArray(16))
        val k1 = doubleBlock(l)
        val k2 = doubleBlock(k1)

        val n = if (message.isEmpty()) 1 else (message.size + 15) / 16
        val lastComplete = message.isNotEmpty() && message.size % 16 == 0
        val lastStart = (n - 1) * 16

        val mLast = ByteArray(16)
        if (lastComplete) {
            for (i in 0 until 16) mLast[i] = (message[lastStart + i].toInt() xor k1[i].toInt()).toByte()
        } else {
            val rem = message.size - lastStart // 0..15
            System.arraycopy(message, lastStart, mLast, 0, rem)
            mLast[rem] = 0x80.toByte()
            for (i in 0 until 16) mLast[i] = (mLast[i].toInt() xor k2[i].toInt()).toByte()
        }

        var x = ByteArray(16)
        val y = ByteArray(16)
        for (block in 0 until n - 1) {
            for (j in 0 until 16) y[j] = (x[j].toInt() xor message[block * 16 + j].toInt()).toByte()
            x = aes.ecbEncryptBlock(y)
        }
        for (j in 0 until 16) y[j] = (x[j].toInt() xor mLast[j].toInt()).toByte()
        return aes.ecbEncryptBlock(y)
    }

    /** Left shift by one bit over GF(2^128), reducing with R128 = 0x87. */
    private fun doubleBlock(input: ByteArray): ByteArray {
        val out = ByteArray(16)
        for (i in 0 until 15) {
            out[i] = (((input[i].toInt() shl 1) or ((input[i + 1].toInt() and 0xFF) ushr 7)) and 0xFF).toByte()
        }
        out[15] = ((input[15].toInt() shl 1) and 0xFF).toByte()
        if ((input[0].toInt() and 0x80) != 0) out[15] = (out[15].toInt() xor RB).toByte()
        return out
    }
}
