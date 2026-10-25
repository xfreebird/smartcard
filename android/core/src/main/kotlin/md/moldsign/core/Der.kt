package md.moldsign.core

/**
 * Minimal DER writer / reader for the CMS and RFC 3161 structures the signers build (docs/02), without an ASN.1
 * library. The Swift reference does the same with hand-rolled `der(tag, content)` helpers.
 */
internal object Der {
    val NULL = byteArrayOf(0x05, 0x00)

    fun concat(vararg parts: ByteArray): ByteArray {
        val out = ByteArray(parts.sumOf { it.size })
        var pos = 0
        for (part in parts) {
            System.arraycopy(part, 0, out, pos, part.size)
            pos += part.size
        }
        return out
    }

    fun tlv(tag: Int, content: ByteArray): ByteArray {
        val len = content.size
        val header = when {
            len < 0x80 -> byteArrayOf(tag.toByte(), len.toByte())
            len < 0x100 -> byteArrayOf(tag.toByte(), 0x81.toByte(), len.toByte())
            len < 0x10000 -> byteArrayOf(tag.toByte(), 0x82.toByte(), (len ushr 8).toByte(), len.toByte())
            else -> byteArrayOf(tag.toByte(), 0x83.toByte(), (len ushr 16).toByte(), (len ushr 8).toByte(), len.toByte())
        }
        return concat(header, content)
    }

    fun seq(vararg parts: ByteArray) = tlv(0x30, concat(*parts))

    fun set(vararg parts: ByteArray) = tlv(0x31, concat(*parts))

    fun oid(encoded: ByteArray) = tlv(0x06, encoded)

    fun octetString(content: ByteArray) = tlv(0x04, content)

    /** Small non-negative INTEGER. */
    fun integer(value: Int): ByteArray = tlv(0x02, byteArrayOf(value.toByte()))

    /** One TLV located inside [data]. */
    class Node(val data: ByteArray, val offset: Int, val tag: Int, val headerLength: Int, val length: Int) {
        val contentOffset: Int get() = offset + headerLength
        val end: Int get() = contentOffset + length
        val content: ByteArray get() = data.copyOfRange(contentOffset, end)

        /** Tag, length and content, as it appears in [data]. */
        val encoded: ByteArray get() = data.copyOfRange(offset, end)

        /** The TLVs inside a constructed node. */
        fun children(): List<Node> {
            val out = ArrayList<Node>()
            var pos = contentOffset
            while (pos < end) {
                val child = read(data, pos)
                if (child.end > end) throw CardError.Format("DER child overruns its parent")
                out += child
                pos = child.end
            }
            return out
        }
    }

    fun read(data: ByteArray, offset: Int = 0): Node {
        if (offset + 2 > data.size) throw CardError.Format("DER truncated at $offset")
        val tag = data[offset].toInt() and 0xFF
        val first = data[offset + 1].toInt() and 0xFF
        val headerLength: Int
        val length: Int
        if (first < 0x80) {
            headerLength = 2
            length = first
        } else {
            val count = first and 0x7F
            if (count !in 1..4 || offset + 2 + count > data.size) throw CardError.Format("Unsupported DER length at $offset")
            var value = 0L
            for (i in 0 until count) value = (value shl 8) or (data[offset + 2 + i].toLong() and 0xFF)
            if (value > Int.MAX_VALUE) throw CardError.Format("DER length too large")
            headerLength = 2 + count
            length = value.toInt()
        }
        if (offset + headerLength + length > data.size) throw CardError.Format("DER content overruns the data at $offset")
        return Node(data, offset, tag, headerLength, length)
    }
}
