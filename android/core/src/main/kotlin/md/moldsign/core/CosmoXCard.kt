package md.moldsign.core

import java.io.ByteArrayOutputStream

/**
 * IDEMIA CosmoX ID-A (IAS/ECC) driver: port of Swift `CosmoXCard` (Card.swift) over [ApduTransport].
 * Same APDU bytes, same SSC handling, same order of operations (docs/09 §3.2).
 *
 * ```
 * authenticate():  SELECT IAS AID → SELECT MF → read D003 (serial) → read D004 (seed)
 *                  → Kenc/Kmac = SHA256(seed‖serial‖MK‖0000000{2,3}) → MSE SET C1A4 → GET CHALLENGE
 *                  → EXTERNAL AUTHENTICATE (96 B) → verify CMAC, decrypt → K_ICC → sessENC/sessMAC, SSC
 * readCertificate(): SM SELECT MF → ADF (P2=04) → EF 0001, READ BINARY 128-byte chunks (outer SEQUENCE)
 * verifyPin(pin):  SM VERIFY ref 03; 63Cx → WrongPin(x); 6983 → PinBlocked
 * sign(digestInfo): SM MSE SET 41A4 800102840181 → INTERNAL AUTHENTICATE → 512-byte RSA-4096
 * ```
 *
 * Not thread-safe: the caller (SigningService) serializes card operations. Nothing secret
 * (keys, PIN, SM payloads) is ever passed to [log] (F-06 / SEC-04).
 */
class CosmoXCard(
    private val transport: ApduTransport,
    private val log: (String) -> Unit = {},
) {
    private var channel: SecureChannel? = null

    /** ASCII chip serial (16 B) from EF D003, available after [authenticate]. Per-card, do not log. */
    var serialNumber: ByteArray = ByteArray(0)
        private set

    /** ASCII random seed (16 B) from EF D004, available after [authenticate]. */
    var randomSeed: ByteArray = ByteArray(0)
        private set

    val isAuthenticated: Boolean get() = channel != null

    // ---------------------------------------------------------------- raw APDUs

    fun transmit(apdu: ByteArray): ApduResponse = ApduResponse.parse(transport.transmit(apdu))

    /** Transmit with the plain GET RESPONSE loop on `61xx` (Swift `transmitFull`). */
    fun transmitFull(apdu: ByteArray): ApduResponse {
        val result = ByteArrayOutputStream()
        var resp = transmit(apdu)
        while (resp.sw1 == 0x61) {
            result.write(resp.data)
            resp = transmit(bytesOf(0x00, 0xC0, 0x00, 0x00, resp.sw2))
        }
        result.write(resp.data)
        return ApduResponse(result.toByteArray(), resp.sw)
    }

    private fun checkSw(sw: Int, context: String) {
        if (sw != 0x9000) throw CardError.fromStatusWord(sw, context)
    }

    // ---------------------------------------------------------------- SM transmit

    /** Wraps [apdu], sends it (with GET RESPONSE chaining) and unwraps the reply. */
    fun smTransmit(apdu: ByteArray): ApduResponse {
        val ch = channel ?: throw CardError.SmOutOfSync("no secure channel: call authenticate() first")
        val wrapped = ch.wrap(apdu)
        val raw = transmitFull(wrapped)
        if (raw.data.isEmpty()) {
            // The card advances the SSC for its response even when it returns a bare SW.
            ch.incrementSsc()
            return ApduResponse(ByteArray(0), raw.sw)
        }
        val swBytes = bytesOf(raw.sw1, raw.sw2)
        return ch.unwrap(raw.data + swBytes)
    }

    // ---------------------------------------------------------------- mutual authentication

    fun authenticate() {
        channel = null
        log("authenticate: SELECT IAS AID")

        // 1. SELECT IAS AID: 00 A4 04 00 Lc AID 00
        val selectAid = bytesOf(0x00, 0xA4, 0x04, 0x00, IAS_AID.size) + IAS_AID + bytesOf(0x00)
        checkSw(transmitFull(selectAid).sw, "SELECT IAS AID")

        // 2. SELECT MF. The Swift reference re-checks the AID's SW here, i.e. it ignores this SW;
        //    kept identical so we behave the same on cards that answer it oddly.
        transmitFull(bytesOf(0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00, 0x00))

        // 3. Serial number: EF D003, 2-byte header then 16 ASCII bytes.
        transmitFull(bytesOf(0x00, 0xA4, 0x02, 0x04, 0x02, 0xD0, 0x03, 0x00))
        val serData = transmitFull(bytesOf(0x00, 0xB0, 0x00, 0x00, 0x00)).data
        serialNumber = serData.drop(2).take(16).toByteArray()

        // 4. Random seed: EF D004, 16 ASCII bytes.
        transmitFull(bytesOf(0x00, 0xA4, 0x02, 0x04, 0x02, 0xD0, 0x04, 0x00))
        randomSeed = transmitFull(bytesOf(0x00, 0xB0, 0x00, 0x00, 0x10)).data.take(16).toByteArray()

        // 5. Admin keys.
        val (kenc, kmac) = deriveAdminKeys(randomSeed, serialNumber)

        // 6. MSE SET for secure messaging.
        checkSw(transmitFull(MSE_SM_APDU).sw, "MSE SET SM")

        // 7. GET CHALLENGE.
        val rndIcc = transmitFull(bytesOf(0x00, 0x84, 0x00, 0x00, 0x10)).data.take(16).toByteArray()

        // 8. EXTERNAL AUTHENTICATE: ct(80) ‖ CMAC(16).
        val snIcc = serialNumber.takeLast(8).toByteArray()
        val (ct, mac) = externalAuthPayload(kenc, kmac, rndIcc, snIcc)
        val extAuth = bytesOf(0x00, 0x82, 0x00, 0x00, 0x60) + ct + mac
        log("authenticate: EXTERNAL AUTHENTICATE")
        val ea = transmitFull(extAuth)
        checkSw(ea.sw, "EXTERNAL AUTHENTICATE")
        if (ea.data.size != 96) throw CardError.Protocol("Bad EXTERNAL AUTHENTICATE response: ${ea.data.size} B")

        // 9. Verify the card's MAC and decode its response.
        channel = decodeAuthResponse(kenc, kmac, ea.data)
        log("authenticate: secure channel established")
    }

    // ---------------------------------------------------------------- SM operations

    fun selectMF() {
        checkSw(smTransmit(bytesOf(0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00, 0x00)).sw, "SELECT MF")
    }

    /** SELECT Generic ADF by AID with P2=04 and Le=00 (P2=04 is required). */
    fun selectGenericADF() {
        val apdu = bytesOf(0x00, 0xA4, 0x04, 0x04, GENERIC_ADF.size) + GENERIC_ADF + bytesOf(0x00)
        checkSw(smTransmit(apdu).sw, "SELECT Generic ADF")
    }

    /** READ BINARY in 128-byte chunks from the currently selected EF. */
    fun readBinary(offset: Int, length: Int): ByteArray {
        val result = ByteArrayOutputStream()
        var remaining = length
        var off = offset
        while (remaining > 0) {
            val chunk = minOf(remaining, READ_CHUNK)
            val resp = smTransmit(bytesOf(0x00, 0xB0, (off ushr 8) and 0x7F, off and 0xFF, chunk))
            checkSw(resp.sw, "READ BINARY")
            // NOTE: Swift `readBinary` calls iso9797Unpad() a SECOND time here, on data that
            // SecureChannel.unwrap() already unpadded. That silently truncates any chunk whose last
            // byte is 00 or 80. The port appends the unwrapped data as is (identical output
            // whenever the reference is correct). Reported for a Swift fix.
            result.write(resp.data)
            off += chunk
            remaining -= chunk
            if (resp.data.isEmpty()) break
        }
        return result.toByteArray()
    }

    /**
     * VERIFY PIN QSCD (reference 0x03). The PIN goes raw (ASCII), SM padding aligns it.
     * `63Cx` → [CardError.WrongPin] (x attempts left), `6983` → [CardError.PinBlocked].
     * Never retried here (R-07).
     */
    fun verifyPin(pin: CharArray) {
        require(pin.size in 4..8 && pin.all { it.code < 0x80 }) { "PIN must be 4-8 ASCII characters" }
        val pinBytes = ByteArray(pin.size) { pin[it].code.toByte() }
        val apdu = bytesOf(0x00, 0x20, 0x00, PIN_REFERENCE, pinBytes.size) + pinBytes
        try {
            val resp = smTransmit(apdu)
            if (resp.sw1 == 0x63) throw CardError.WrongPin(resp.sw2 and 0x0F)
            checkSw(resp.sw, "VERIFY")
        } finally {
            pinBytes.fill(0)
            apdu.fill(0)
        }
    }

    /** MSE SET (41 A4, key 02, algo 81) + INTERNAL AUTHENTICATE with a DigestInfo → raw RSA signature. */
    fun sign(digestInfo: ByteArray): ByteArray {
        require(digestInfo.size <= 0xFF) { "DigestInfo too long" }
        val mse = bytesOf(0x00, 0x22, 0x41, 0xA4, MSE_SIGN_DATA.size) + MSE_SIGN_DATA
        checkSw(smTransmit(mse).sw, "MSE SET sign")
        val ia = bytesOf(0x00, 0x88, 0x00, 0x00, digestInfo.size) + digestInfo
        val resp = smTransmit(ia)
        checkSw(resp.sw, "INTERNAL AUTHENTICATE")
        return resp.data
    }

    /** Signing certificate from EF 0001 under the Generic ADF: the FULL X.509 (outer SEQUENCE). */
    fun readCertificate(): ByteArray {
        selectMF()
        selectGenericADF()
        smTransmit(bytesOf(0x00, 0xA4, 0x02, 0x04, 0x02, 0x00, 0x01, 0x00)) // SELECT EF 0001 (SW unchecked, as in Swift)

        val header = readBinary(0, 16)
        if (header.size < 4 || header.u8(0) != 0x30 || header.u8(1) != 0x82) {
            throw CardError.Protocol("Certificate file doesn't start with SEQUENCE")
        }
        val outerLen = 4 + (header.u8(2) shl 8) + header.u8(3)
        val body = readBinary(4, outerLen - 4)
        val file = header.copyOf(4) + body
        if (file.size <= 8 || file.u8(4) != 0x30 || file.u8(5) != 0x82) {
            throw CardError.Protocol("No certificate in EF 0001")
        }
        // The outer SEQUENCE is the whole Certificate (TBS + signatureAlgorithm + signature).
        return file.copyOf(minOf(outerLen, file.size))
    }

    /**
     * Swift `prepareForSigning`: SELECT MF → ADF → read EF 0001 → identity check → SELECT ADF → VERIFY.
     * The certificate is read and compared before the PIN goes out, so a swapped card never receives another
     * card's PIN ([CardError.CardChanged], docs/09 §3.1b). Returns the certificate DER.
     */
    fun prepareForSigning(pin: CharArray, expectedCertificateSha1: String?): ByteArray {
        val cert = readCertificate() // SELECT MF → ADF → EF 0001 → READ BINARY
        checkIdentity(cert, expectedCertificateSha1)
        selectGenericADF()
        verifyPin(pin)
        return cert
    }

    /** Forgets the session (does not close the transport, which the caller owns). */
    fun reset() {
        channel = null
    }

    companion object {
        val IAS_AID: ByteArray get() = "A000000077030C60000000FE00000500".decodeHex()
        val GENERIC_ADF: ByteArray get() = "E828BD080FD25047656E65726963".decodeHex()
        val MK_CLASS: ByteArray get() = "C1765FCA5C11B6E9F827EB1230FA74C3140619976CE92B66199801CFDB125F1E".decodeHex()
        val RND_IFD: ByteArray get() = "199F0388C3ACEC2D84C6CE4CE785CB7B".decodeHex()
        val SN_IFD: ByteArray get() = "4A95FED1DB606A62".decodeHex()
        val K_IFD: ByteArray get() = "445969C4020CEDD4A8C4BFCE4B9820D2BE8CDD972F983B813038A512905BBF08".decodeHex()
        val MSE_SM_APDU: ByteArray get() = "0022C1A4098004FF40108C830104".decodeHex()
        val MSE_SIGN_DATA: ByteArray get() = "800102840181".decodeHex()
        const val PIN_REFERENCE = 0x03
        const val READ_CHUNK = 128

        /**
         * Identity guard (docs/09 §3.1b): throws [CardError.CardChanged] unless SHA-1([certificateDer]) equals
         * [expectedSha1Hex] (hex, any case). `null` means "no expectation" (the consent shows this card's own
         * certificate, so the PIN is asked for this card).
         */
        fun checkIdentity(certificateDer: ByteArray, expectedSha1Hex: String?) {
            if (expectedSha1Hex == null) return
            val actual = Sha.sha1(certificateDer).toHex()
            if (!actual.equals(expectedSha1Hex.trim(), ignoreCase = true)) {
                throw CardError.CardChanged(expectedSha1Hex, actual)
            }
        }

        /** Kenc = SHA256(seed ‖ serial ‖ MK ‖ 00000002), Kmac = … ‖ 00000003. */
        fun deriveAdminKeys(seed: ByteArray, serial: ByteArray): Pair<ByteArray, ByteArray> {
            val base = seed + serial + MK_CLASS
            return Sha.sha256(base, bytesOf(0, 0, 0, 2)) to Sha.sha256(base, bytesOf(0, 0, 0, 3))
        }

        /** plain = RND.IFD ‖ SN.IFD ‖ RND.ICC ‖ SN.ICC ‖ K.IFD; ct = AES-CBC(kenc, IV=0); mac = CMAC(kmac, ct). */
        fun externalAuthPayload(kenc: ByteArray, kmac: ByteArray, rndIcc: ByteArray, snIcc: ByteArray): Pair<ByteArray, ByteArray> {
            val plain = RND_IFD + SN_IFD + rndIcc + snIcc + K_IFD
            if (plain.size % 16 != 0) throw CardError.Protocol("Unexpected challenge/serial length (${plain.size} B payload)")
            val ct = Aes(kenc).cbcEncrypt(plain, Aes.ZERO_IV)
            return ct to Cmac.aesCmac(kmac, ct)
        }

        /** Session keys from K.ICC: secret = K.ICC ⊕ K.IFD; sessENC/sessMAC = SHA256(secret ‖ 00000001/2). */
        fun deriveSessionKeys(kIcc: ByteArray): Pair<ByteArray, ByteArray> {
            val secret = xorBytes(kIcc, K_IFD)
            return Sha.sha256(secret, bytesOf(0, 0, 0, 1)) to Sha.sha256(secret, bytesOf(0, 0, 0, 2))
        }

        /**
         * Verifies the 96-byte EXTERNAL AUTHENTICATE response (ct(80) ‖ CMAC(16)), decrypts it and
         * builds the secure channel: K.ICC = plain[48..80), SSC = plain[8..16) ‖ RND.IFD[8..16).
         */
        fun decodeAuthResponse(kenc: ByteArray, kmac: ByteArray, response: ByteArray): SecureChannel {
            require(response.size == 96) { "EXTERNAL AUTHENTICATE response must be 96 bytes" }
            val respCt = response.copyOfRange(0, 80)
            val respMac = response.copyOfRange(80, 96)
            if (!Cmac.aesCmac(kmac, respCt).contentEquals(respMac)) {
                throw CardError.SmOutOfSync("mutual authentication MAC mismatch")
            }
            val plain = Aes(kenc).cbcDecrypt(respCt, Aes.ZERO_IV)
            val kIcc = plain.copyOfRange(48, 80)
            val (sessEnc, sessMac) = deriveSessionKeys(kIcc)
            val ssc = plain.copyOfRange(8, 16) + RND_IFD.copyOfRange(8, 16)
            return SecureChannel(sessEnc, sessMac, ssc)
        }
    }
}
