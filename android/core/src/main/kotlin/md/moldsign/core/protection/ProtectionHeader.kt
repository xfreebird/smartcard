package md.moldsign.core.protection

/** Routes the dialog using a short prefix. Each codec still validates the complete envelope. */
data class ProtectionHeader(val certificate: Boolean, val aesKeySize: Int? = null) {
    companion object {
        const val PREFIX_SIZE = 96
        private val cmsOidPrefix = byteArrayOf(6, 9, 42, -122, 72, -122, -9, 13, 1, 7)

        fun detect(prefix: ByteArray): ProtectionHeader? {
            PasswordFileProtection.keySize(prefix)?.let { return ProtectionHeader(false, it) }
            if (prefix.size < 2 || prefix[0] != 0x30.toByte()) return null
            // Streaming vendor files use BER indefinite lengths. Definite lengths fit in four bytes.
            val length = prefix[1].toInt() and 255
            if (length > 0x84) return null
            val start = if (length <= 0x80) 2 else 2 + (length and 127)
            fun matches(bytes: ByteArray) = bytes.indices.all { prefix.getOrNull(start + it) == bytes[it] }
            if (matches(cmsOidPrefix)) return when (prefix.getOrNull(start + cmsOidPrefix.size)?.toInt()) {
                3 -> ProtectionHeader(true)
                6 -> ProtectionHeader(false)
                else -> null
            }
            // Bare EnvelopedData and EncryptedData begin with version 0, then SET or SEQUENCE.
            if (matches(byteArrayOf(2, 1, 0))) return when (prefix.getOrNull(start + 3)?.toInt()) {
                0x31 -> ProtectionHeader(true)
                0x30 -> ProtectionHeader(false)
                else -> null
            }
            return null
        }
    }
}
