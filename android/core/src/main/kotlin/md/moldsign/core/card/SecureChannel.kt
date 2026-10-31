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

        // Parse the original body exactly like the Swift reference.
        val body = apdu.copyOfRange(4, apdu.size)
        var cmdData = ByteArray(0)
        var le: Byte? = null
        if (body.size == 1) {
            // Case 2: CLA INS P1 P2 Le. Never read body[0] as Lc here (docs/01).
            le = body[0]
        } else if (body.size > 1) {
            val lc = body.u8(0)
            if (lc > 0 && 1 + lc <= body.size) cmdData = body.copyOfRange(1, 1 + lc)
            if (body.size > 1 + lc) le = body[body.size - 1]
        }

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
            val tlv = tlv(0x97, byteArrayOf(le))
            macInput.write(tlv)
            dataField.write(tlv)
        }

        val mac = Cmac.aesCmac(sessMac, Iso9797.pad(ssc1 + macInput.toByteArray())).copyOf(8)
        dataField.write(tlv(0x8E, mac))

        val fields = dataField.toByteArray()
        require(fields.size <= 0xFF) { "SM body too long for a short APDU (${fields.size} B)" }
        val out = ByteArrayOutputStream(fields.size + 6)
        out.write(byteArrayOf(cla, ins, p1, p2, fields.size.toByte()))
        out.write(fields)
        out.write(0x00) // the vendor Lua driver always appends Le=00
        return out.toByteArray()
    }

    /**
     * Unwraps an SM response (`TLVs ‖ SW1 SW2`). Increments the SSC once, verifies tag 8E when
     * present, decrypts tag 87/85 and returns (plain data, SW from tag 99 or the transport SW).
     *
     * Throws [CardError.SmOutOfSync] on a MAC mismatch or an undecryptable payload.
     */
    fun unwrap(response: ByteArray): ApduResponse {
        if (response.size <= 2) return ApduResponse.parse(response)

        val swTail = response.copyOfRange(response.size - 2, response.size)
        val body = response.copyOfRange(0, response.size - 2)

        var resultData = ByteArray(0)
        var resultSw = ByteArray(0)
        var respMac = ByteArray(0)
        val ssc1 = incrementSsc()
        val calcMac = ByteArrayOutputStream()
        calcMac.write(ssc1)

        var pos = 0
        while (pos < body.size) {
            if (pos + 1 >= body.size) break
            val tag = body.u8(pos)
            val l1 = body.u8(pos + 1)
            val len: Int
            val hdrLen: Int
            when {
                l1 < 0x80 -> { len = l1; hdrLen = 2 }
                l1 == 0x81 && pos + 2 < body.size -> { len = body.u8(pos + 2); hdrLen = 3 }
                l1 == 0x82 && pos + 3 < body.size -> { len = (body.u8(pos + 2) shl 8) or body.u8(pos + 3); hdrLen = 4 }
                else -> break
            }
            val contentStart = pos + hdrLen
            val contentEnd = contentStart + len
            if (contentEnd > body.size) break
            val content = body.copyOfRange(contentStart, contentEnd)
            val fullTlv = body.copyOfRange(pos, contentEnd)

            when (tag) {
                0x87 -> {
                    calcMac.write(fullTlv)
                    val enc = if (content.size > 1) content.copyOfRange(1, content.size) else content
                    resultData = decrypt(enc, ssc1)
                }
                0x85 -> {
                    calcMac.write(fullTlv)
                    resultData = decrypt(content, ssc1)
                }
                0x99 -> {
                    calcMac.write(fullTlv)
                    resultSw = content
                }
                0x8E -> respMac = content
            }
            pos = contentEnd
        }

        // Like the reference, a response without tag 8E is not MAC-checked.
        if (respMac.isNotEmpty()) {
            val expected = Cmac.aesCmac(sessMac, Iso9797.pad(calcMac.toByteArray())).copyOf(8)
            if (!expected.contentEquals(respMac)) throw CardError.SmOutOfSync("response MAC mismatch")
        }

        if (resultData.isNotEmpty()) resultData = Iso9797.unpad(resultData)

        val swBytes = if (resultSw.isEmpty()) swTail else resultSw
        if (swBytes.size != 2) throw CardError.CardNotResponding("Malformed SW in tag 99 (${swBytes.size} B)")
        return ApduResponse(resultData, (swBytes.u8(0) shl 8) or swBytes.u8(1))
    }

    private fun decrypt(enc: ByteArray, ssc1: ByteArray): ByteArray {
        if (enc.size % Aes.BLOCK != 0) throw CardError.SmOutOfSync("encrypted SM payload is ${enc.size} B, not a multiple of 16")
        return aesEnc.cbcDecrypt(enc, aesEnc.ecbEncryptBlock(ssc1))
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
