package md.moldsign.core

import java.io.ByteArrayOutputStream

/**
 * IAS/ECC secure messaging (AES-256-CBC + AES-CMAC/8), line-by-line port of Swift `SecureChannel`.
 *
 * Rules (docs/01, spec/vectors `sm.comment`):
 * - CLA |= 0x0C; the SSC is incremented BEFORE wrapping a command and BEFORE unwrapping a response.
 * - IV = AES-ECB(sessENC, SSC); data → ISO 9797-2 pad → AES-CBC → tag 87 (`01 ‖ ct`) for even INS,
 *   tag 85 for odd INS; Le → tag 97.
 * - MAC = AES-CMAC(sessMAC, pad(SSC ‖ pad(header) ‖ TLVs))[0..8) in tag 8E.
 * - Lc = len(TLVs) and Le=00 is ALWAYS appended (also for case-3 APDUs), else long responses truncate.
 * - A SW-only response still consumes one SSC step: callers use [incrementSsc] for it.
 *
 * Not thread-safe; one channel belongs to one card session (docs/09 §1 "one card operation at a time").
 */
class SecureChannel(sessEnc: ByteArray, sessMac: ByteArray, ssc: ByteArray) {
    private val aesEnc = Aes(sessEnc)
    private val sessMac: ByteArray = sessMac.copyOf()
    private val counter: ByteArray

    init {
        require(sessEnc.size == 32 && sessMac.size == 32) { "Session keys must be 32 bytes" }
        require(ssc.size == 16) { "SSC must be 16 bytes, got ${ssc.size}" }
        counter = ssc.copyOf()
    }

    /** Current SSC (copy). */
    val ssc: ByteArray get() = counter.copyOf()

    /** Increments the SSC as a big-endian 128-bit integer and returns the new value. */
    fun incrementSsc(): ByteArray {
        for (i in 15 downTo 0) {
            counter[i] = (counter[i] + 1).toByte()
            if (counter[i].toInt() != 0) break
        }
        return counter.copyOf()
    }

    /** Wraps a plain short command APDU (case 1–4) into an SM APDU. */
    fun wrap(apdu: ByteArray): ByteArray {
        require(apdu.size >= 4) { "APDU shorter than its header" }
        val cla = (apdu[0].toInt() or 0x0C).toByte()
        val ins = apdu[1]
        val p1 = apdu[2]
        val p2 = apdu[3]

        val body = apdu.copyOfRange(4, apdu.size)
        var cmdData = ByteArray(0)
        var le: ByteArray? = null
        val extended = body.size > 1 && body[0] == 0.toByte()
        if (body.size == 1) le = body
        else if (extended) {
            require(body.size >= 3)
            if (body.size == 3) le = body.copyOfRange(1,3)
            else {
                val count = body.u8(1) * 256 + body.u8(2)
                require(count > 0 && (body.size == count+3 || body.size == count+5))
                cmdData = body.copyOfRange(3,3+count)
                if (body.size == count+5) le = body.copyOfRange(body.size-2,body.size)
            }
        } else if (body.size > 1) {
            val count = body.u8(0)
            require(body.size == count+1 || body.size == count+2)
            cmdData = body.copyOfRange(1,1+count)
            if (body.size == count+2) le = byteArrayOf(body.last())
        }

        require(cmdData.size <= 65488) { "Secure APDU payload too large" }
        val ssc1 = incrementSsc()

        val macInput = ByteArrayOutputStream()
        macInput.write(Iso9797.pad(byteArrayOf(cla, ins, p1, p2)))
        val dataField = ByteArrayOutputStream()

        if (cmdData.isNotEmpty()) {
            val iv = aesEnc.ecbEncryptBlock(ssc1)
            val enc = aesEnc.cbcEncrypt(Iso9797.pad(cmdData), iv)
            val tlv = if ((ins.toInt() and 1) == 0) tlv(0x87, byteArrayOf(0x01) + enc) else tlv(0x85, enc)
            macInput.write(tlv)
            dataField.write(tlv)
        }

        if (le != null) {
            val tlv = tlv(0x97, le)
            macInput.write(tlv)
            dataField.write(tlv)
        }

        val mac = Cmac.aesCmac(sessMac, Iso9797.pad(ssc1 + macInput.toByteArray())).copyOf(8)
        dataField.write(tlv(0x8E, mac))

        val fields = dataField.toByteArray()
        require(fields.size <= 65535)
        val out = ByteArrayOutputStream(fields.size + 9)
        out.write(byteArrayOf(cla, ins, p1, p2))
        if (extended || fields.size > 255) {
            out.write(byteArrayOf(0,(fields.size ushr 8).toByte(),fields.size.toByte()))
            out.write(fields); out.write(byteArrayOf(0,0))
        } else { out.write(fields.size); out.write(fields); out.write(0) }
        return out.toByteArray()
    }

    /** Authenticates the complete response before decrypting; status and MAC are mandatory. */
    fun unwrap(response: ByteArray): ApduResponse {
        val ssc1 = incrementSsc()
        fun invalid(): Nothing = throw CardError.SmOutOfSync("Malformed or unauthenticated secure response")
        if (response.size < 2) invalid()
        if (response.size == 2) {
            val parsed = ApduResponse.parse(response)
            if (parsed.sw == 0x9000) invalid()
            return parsed
        }
        if (response.takeLast(2) != listOf(0x90.toByte(), 0.toByte())) invalid()
        val body = response.copyOf(response.size - 2)
        var pos = 0
        var encrypted: ByteArray? = null
        var status: Int? = null
        var mac: ByteArray? = null
        var macStart = 0
        while (pos < body.size) {
            val start = pos
            if (pos + 2 > body.size) invalid()
            val tag = body.u8(pos++)
            var len = body.u8(pos++)
            if (len >= 128) {
                val n = len and 127
                if (n !in 1..2 || pos + n > body.size || body.u8(pos) == 0) invalid()
                len = 0
                repeat(n) { len = len * 256 + body.u8(pos++) }
                if (len < 128 || (n == 2 && len < 256)) invalid()
            }
            if (pos + len > body.size || mac != null) invalid()
            val value = body.copyOfRange(pos, pos + len)
            pos += len
            when (tag) {
                0x87, 0x85 -> {
                    if (encrypted != null || status != null) invalid()
                    encrypted = if (tag == 0x87) {
                        if (value.isEmpty() || value[0] != 1.toByte()) invalid()
                        value.copyOfRange(1, value.size)
                    } else value
                    if (encrypted.isEmpty() || encrypted.size % 16 != 0) invalid()
                }
                0x99 -> { if (status != null || len != 2) invalid(); status = value.u8(0) * 256 + value.u8(1) }
                0x8E -> { if (status == null || len != 8 || pos != body.size) invalid(); mac = value; macStart = start }
                else -> invalid()
            }
        }
        if (status == null || mac == null) invalid()
        val expected = Cmac.aesCmac(sessMac, Iso9797.pad(ssc1 + body.copyOf(macStart))).copyOf(8)
        if (!java.security.MessageDigest.isEqual(expected, mac)) invalid()
        val plain = encrypted?.let {
            val padded = aesEnc.cbcDecrypt(it, aesEnc.ecbEncryptBlock(ssc1))
            var end = padded.lastIndex
            while (end >= 0 && padded[end] == 0.toByte()) end--
            if (end < 0 || padded[end] != 0x80.toByte()) invalid()
            padded.copyOf(end)
        } ?: ByteArray(0)
        return ApduResponse(plain, status)
    }

    companion object {
        /** BER-TLV with short / 81 / 82 length forms (Swift `buildTLV`). */
        fun tlv(tag: Int, content: ByteArray): ByteArray {
            val out = ByteArrayOutputStream(content.size + 4)
            out.write(tag)
            when {
                content.size < 0x80 -> out.write(content.size)
                content.size < 0x100 -> { out.write(0x81); out.write(content.size) }
                else -> { out.write(0x82); out.write(content.size ushr 8); out.write(content.size and 0xFF) }
            }
            out.write(content)
            return out.toByteArray()
        }
    }
}
