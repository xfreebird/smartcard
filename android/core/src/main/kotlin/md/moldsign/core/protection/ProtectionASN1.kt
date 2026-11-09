package md.moldsign.core.protection

internal data class ProtectionASN1(val tag: Int, val content: ByteArray, val encoded: ByteArray, val children: List<ProtectionASN1>) {
    fun requireTag(expected: Int, count: Int? = null): List<ProtectionASN1> {
        require(tag == expected && (count == null || children.size == count)) { "Unsupported encrypted file." }
        return children
    }
    fun octets(context: Boolean = false): ByteArray {
        if (tag == 4 || (context && tag == 0x80)) return content
        require(tag == 0x24 || (context && tag == 0xa0)) { "Invalid encrypted content." }
        return java.io.ByteArrayOutputStream().also { out -> children.forEach { out.write(it.octets()) } }.toByteArray()
    }
    companion object {
        fun parse(data: ByteArray): ProtectionASN1 {
            require(data.size <= PasswordFileProtection.MAXIMUM_SIZE + 8192)
            var position = 0; var budget = 100_000; var storage = 4*1024*1024
            fun read(end: Int, depth: Int): ProtectionASN1 {
                require(depth < 24 && budget-- > 0 && position + 2 <= end)
                val start = position; val tag = data[position++].toInt() and 255
                require(tag != 0 && tag and 31 != 31)
                val first = data[position++].toInt() and 255; val indefinite = first == 128
                var length = first.toLong()
                if (first > 128) {
                    val count = first and 127; require(count <= 4 && position + count <= end)
                    length = 0
                    repeat(count) { length = length * 256 + (data[position++].toInt() and 255) }
                }
                require((!indefinite || tag and 32 != 0) && (indefinite || length <= end - position))
                val body = position; val boundary = if (indefinite) end else position + length.toInt()
                val children = mutableListOf<ProtectionASN1>()
                if (tag and 32 != 0) {
                    while (position < boundary) {
                        if (indefinite && position + 2 <= end && data[position] == 0.toByte() && data[position+1] == 0.toByte()) break
                        children += read(boundary,depth+1)
                    }
                } else position = boundary
                val contentEnd = position
                if (indefinite) { require(position + 2 <= end && data[position] == 0.toByte() && data[position+1] == 0.toByte()); position += 2 }
                val retain = tag != 4 && position-start<=65536
                if(retain) { storage-=position-start;require(storage>=0) }
                return ProtectionASN1(tag,if(tag and 32 == 0) data.copyOfRange(body,contentEnd) else byteArrayOf(),if(retain) data.copyOfRange(start,position) else byteArrayOf(),children)
            }
            return read(data.size,0).also { require(position == data.size) }
        }
        fun wrap(tag: Int, content: ByteArray): ByteArray {
            var length = content.size
            var len = byteArrayOf()
            if (length < 128) len = byteArrayOf(length.toByte()) else {
                while (length > 0) { len = byteArrayOf((length and 255).toByte()) + len; length = length ushr 8 }
                len = byteArrayOf((128 or len.size).toByte()) + len
            }
            return byteArrayOf(tag.toByte()) + len + content
        }
    }
}
