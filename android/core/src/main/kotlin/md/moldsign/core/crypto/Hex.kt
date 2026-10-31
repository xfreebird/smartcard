package md.moldsign.core

/** Upper-case hex, no separators (the format used by `spec/vectors/` and the Swift `hexString`). */
object Hex {
    private val DIGITS = "0123456789ABCDEF".toCharArray()

    fun encode(bytes: ByteArray): String {
        val out = CharArray(bytes.size * 2)
        for (i in bytes.indices) {
            val v = bytes[i].toInt() and 0xFF
            out[i * 2] = DIGITS[v ushr 4]
            out[i * 2 + 1] = DIGITS[v and 0x0F]
        }
        return String(out)
    }

    /** Decodes hex, ignoring whitespace. Throws [IllegalArgumentException] on odd length or bad digits. */
    fun decode(hex: String): ByteArray {
        val clean = hex.filterNot { it.isWhitespace() }
        require(clean.length % 2 == 0) { "Odd-length hex string" }
        return ByteArray(clean.length / 2) { i ->
            val hi = Character.digit(clean[i * 2], 16)
            val lo = Character.digit(clean[i * 2 + 1], 16)
            require(hi >= 0 && lo >= 0) { "Invalid hex digit near index ${i * 2}" }
            ((hi shl 4) or lo).toByte()
        }
    }
}

fun ByteArray.toHex(): String = Hex.encode(this)

fun String.decodeHex(): ByteArray = Hex.decode(this)

internal fun bytesOf(vararg values: Int): ByteArray = ByteArray(values.size) { values[it].toByte() }

internal fun ByteArray.u8(index: Int): Int = this[index].toInt() and 0xFF
