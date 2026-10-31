package md.moldsign.core

/** ISO/IEC 9797-1 padding method 2 (`80 00 …`), as used by IAS/ECC secure messaging. */
object Iso9797 {
    /** Always appends `80` then zeros up to the next multiple of [blockSize] (a full block for aligned input). */
    fun pad(data: ByteArray, blockSize: Int = 16): ByteArray {
        val padded = ((data.size + 1 + blockSize - 1) / blockSize) * blockSize
        val out = ByteArray(padded)
        System.arraycopy(data, 0, out, 0, data.size)
        out[data.size] = 0x80.toByte()
        return out
    }

    /**
     * Port of Swift `AES.iso9797Unpad`: strips trailing `00` bytes, then one trailing `80` if present.
     * Lenient on purpose (an unpadded input that ends in zeros loses them), matching the reference.
     */
    fun unpad(data: ByteArray): ByteArray {
        var end = data.size
        while (end > 0 && data[end - 1].toInt() == 0) end--
        if (end > 0 && data[end - 1] == 0x80.toByte()) end--
        return data.copyOf(end)
    }
}
