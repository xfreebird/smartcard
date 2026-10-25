package md.moldsign.core

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.io.ByteArrayOutputStream

/**
 * Drives [CosmoXCard] against a simulated CosmoX card built from the golden vectors.
 * The simulator keeps its OWN SSC and verifies every command MAC, so any host-side SSC drift
 * (e.g. forgetting the step for a SW-only response) fails like the real card would (6988).
 */
class CosmoXCardTest {
    private val v = SpecFiles.cardCrypto

    @Test
    fun authenticateReadCertificateVerifyAndSign() {
        val sim = SimulatedCard(v)
        val card = CosmoXCard(sim)
        card.authenticate()
        assertTrue(card.isAuthenticated)
        assertEquals(v.obj("kdf").str("serial_ascii"), String(card.serialNumber, Charsets.US_ASCII))

        card.selectMF()
        card.selectGenericADF()
        assertArrayEquals(sim.certificate, card.readCertificate())

        card.selectGenericADF()
        card.verifyPin(SimulatedCard.PIN.toCharArray())
        val di = DigestInfo.sha256("abc".toByteArray())
        val sig = card.sign(di)
        assertEquals(512, sig.size)
        assertArrayEquals(SimulatedCard.fakeSignature(di), sig)
        assertTrue("signature response used GET RESPONSE chaining", sim.getResponses > 0)
    }

    @Test
    fun wrongPinReportsRemainingAndKeepsSscInSync() {
        val sim = SimulatedCard(v)
        val card = CosmoXCard(sim).apply { authenticate() }
        try {
            card.verifyPin("00000000".toCharArray())
            fail("expected WrongPin")
        } catch (e: CardError.WrongPin) {
            assertEquals(2, e.remaining)
        }
        // The SW-only 63C2 consumed an SSC step on both sides: the next MAC must still verify.
        card.selectGenericADF()
        card.verifyPin(SimulatedCard.PIN.toCharArray())
    }

    @Test(expected = CardError.PinBlocked::class)
    fun pinBlocked() {
        val sim = SimulatedCard(v).apply { verifyOverride = 0x6983 }
        CosmoXCard(sim).apply { authenticate() }.verifyPin(SimulatedCard.PIN.toCharArray())
    }

    @Test(expected = CardError.CardStateStuck::class)
    fun conditionsNotSatisfiedIsCardStateStuck() {
        val sim = SimulatedCard(v).apply { mseOverride = 0x6985 }
        CosmoXCard(sim).apply { authenticate() }.sign(DigestInfo.sha256(byteArrayOf(1)))
    }

    @Test(expected = CardError.SmOutOfSync::class)
    fun sw6988IsSmOutOfSync() {
        val sim = SimulatedCard(v).apply { selectOverride = 0x6988 }
        CosmoXCard(sim).apply { authenticate() }.selectMF()
    }

    @Test
    fun plainAuthApdusMatchReference() {
        val sim = SimulatedCard(v)
        CosmoXCard(sim).authenticate()
        val expected = listOf(
            "00A404001" + "0" + v.obj("constants").str("ias_aid") + "00",
            "00A4000C023F0000",
            "00A4020402D00300",
            "00B0000000",
            "00A4020402D00400",
            "00B0000010",
            v.obj("constants").str("mse_sm_apdu"),
            "0084000010",
        )
        assertEquals(expected, sim.plainLog.take(expected.size))
        assertTrue(sim.plainLog[expected.size].startsWith("0082000060"))
    }
}

/**
 * Card-side IAS/ECC + SM simulator. [certificateDer] is what EF 0001 holds (default: a 1799-byte pseudo
 * certificate that is not parseable X.509). Shared with [IdentityGuardTest].
 */
internal class SimulatedCard(v: Any?, certificateDer: ByteArray? = null) : ApduTransport {
    companion object {
        const val PIN = "123456"

        fun fakeSignature(digestInfo: ByteArray): ByteArray {
            val out = ByteArrayOutputStream()
            var block = digestInfo
            while (out.size() < 512) {
                block = Sha.sha256(block)
                out.write(block)
            }
            return out.toByteArray().copyOf(512)
        }
    }

    override val readerName = "Simulated miniLector"
    val plainLog = mutableListOf<String>()
    var getResponses = 0
    var verifyOverride: Int? = null
    var mseOverride: Int? = null
    var selectOverride: Int? = null

    private val kdf = v.obj("kdf")
    private val serial = kdf.str("serial_ascii").toByteArray(Charsets.US_ASCII)
    private val seed = kdf.str("seed_ascii").toByteArray(Charsets.US_ASCII)
    private val ea = v.obj("external_auth")
    private val authResponse = v.obj("response_decode").hex("response")

    private var sessEnc: Aes? = null
    private var sessMac = ByteArray(0)
    private var ssc = ByteArray(16)
    private var pending = ByteArray(0)
    private var selectedFile = ""
    /** PIN retry counter as the card keeps it: a test can prove a PIN never reached this card. */
    var attempts = 3
        private set

    /** 1799-byte pseudo certificate; chunk ends at file offsets 131/259 are 00/80 (double-unpad trap). */
    val certificate: ByteArray = certificateDer ?: ByteArray(1799) { (it * 7 + 3).toByte() }.also {
        val outer = it.size - 4
        it[0] = 0x30; it[1] = 0x82.toByte(); it[2] = (outer ushr 8).toByte(); it[3] = outer.toByte()
        it[4] = 0x30; it[5] = 0x82.toByte(); it[6] = 0x04; it[7] = 0xEB.toByte()
        it[131] = 0x00
        it[259] = 0x80.toByte()
        it[387] = 0x00; it[386] = 0x00
    }

    override fun transmit(apdu: ByteArray): ByteArray {
        if ((apdu.u8(0) and 0x0C) == 0x0C) return smCommand(apdu)
        val hex = apdu.toHex()
        plainLog += hex
        return when {
            hex.startsWith("00C00000") -> {
                getResponses++
                val n = apdu.u8(4).let { if (it == 0) 256 else it }
                chunk(n)
            }
            hex.startsWith("00A40400") -> ok()
            hex == "00A4000C023F0000" -> ok()
            hex == "00A4020402D00300" -> { selectedFile = "D003"; ok() }
            hex == "00A4020402D00400" -> { selectedFile = "D004"; ok() }
            hex == "00B0000000" && selectedFile == "D003" -> bytesOf(0x04, 0x10) + serial + ok()
            hex == "00B0000010" && selectedFile == "D004" -> seed + ok()
            hex == "0022C1A4098004FF40108C830104" -> ok()
            hex == "0084000010" -> ea.hex("rnd_icc") + ok()
            hex.startsWith("0082000060") -> {
                val payload = apdu.copyOfRange(5, apdu.size)
                assertEquals("EXTERNAL AUTHENTICATE payload", ea.str("ciphertext") + ea.str("cmac"), payload.toHex())
                openSession()
                authResponse + ok()
            }
            else -> sw(0x6D00)
        }
    }

    private fun openSession() {
        val (kenc, _) = CosmoXCard.deriveAdminKeys(seed, serial)
        val plain = Aes(kenc).cbcDecrypt(authResponse.copyOfRange(0, 80), ByteArray(16))
        val secret = xorBytes(plain.copyOfRange(48, 80), CosmoXCard.K_IFD)
        sessEnc = Aes(Sha.sha256(secret, bytesOf(0, 0, 0, 1)))
        sessMac = Sha.sha256(secret, bytesOf(0, 0, 0, 2))
        ssc = plain.copyOfRange(8, 16) + CosmoXCard.RND_IFD.copyOfRange(8, 16)
    }

    private fun inc() {
        for (i in 15 downTo 0) {
            ssc[i] = (ssc[i] + 1).toByte()
            if (ssc[i].toInt() != 0) break
        }
    }

    private fun smCommand(apdu: ByteArray): ByteArray {
        val enc = sessEnc ?: return sw(0x6988)
        assertEquals("SM APDU must end with Le=00", 0, apdu.u8(apdu.size - 1))
        val lc = apdu.u8(4)
        assertEquals("Lc covers the TLVs", apdu.size - 6, lc)
        val tlvs = apdu.copyOfRange(5, 5 + lc)
        inc()
        // Parse TLVs and check the MAC with the card's own SSC.
        var pos = 0
        var data = ByteArray(0)
        var le: Int? = null
        var macEnd = 0
        var mac = ByteArray(0)
        while (pos < tlvs.size) {
            val tag = tlvs.u8(pos)
            var len = tlvs.u8(pos + 1)
            var hdr = 2
            if (len == 0x81) { len = tlvs.u8(pos + 2); hdr = 3 }
            val content = tlvs.copyOfRange(pos + hdr, pos + hdr + len)
            when (tag) {
                0x87 -> data = Iso9797.unpad(enc.cbcDecrypt(content.copyOfRange(1, content.size), enc.ecbEncryptBlock(ssc)))
                0x97 -> le = content.u8(0)
                0x8E -> { mac = content; macEnd = pos }
            }
            pos += hdr + len
        }
        val header = bytesOf(apdu.u8(0), apdu.u8(1), apdu.u8(2), apdu.u8(3))
        val expected = Cmac.aesCmac(sessMac, Iso9797.pad(ssc + Iso9797.pad(header) + tlvs.copyOfRange(0, macEnd))).copyOf(8)
        if (!expected.contentEquals(mac)) return sw(0x6988)

        val ins = apdu.u8(1)
        plainLog += "SM:%02X".format(ins)
        return when (ins) {
            0xA4 -> {
                if (data.contentEquals(bytesOf(0x00, 0x01))) selectedFile = "0001"
                if (apdu.u8(2) == 0x04) assertArrayEquals("Generic ADF AID", CosmoXCard.GENERIC_ADF, data)
                swOnly(selectOverride ?: 0x9000)
            }
            0xB0 -> {
                val off = ((apdu.u8(2) and 0x7F) shl 8) or apdu.u8(3)
                val n = (le ?: 0).let { if (it == 0) 256 else it }
                smData(certificate.copyOfRange(off, minOf(off + n, certificate.size)))
            }
            0x20 -> {
                assertEquals("PIN reference", 0x03, apdu.u8(3))
                when {
                    verifyOverride != null -> swOnly(verifyOverride!!)
                    String(data, Charsets.US_ASCII) == PIN -> { attempts = 3; swOnly(0x9000) }
                    else -> { attempts--; swOnly(0x63C0 or attempts) }
                }
            }
            0x22 -> {
                assertEquals("41A4", "%02X%02X".format(apdu.u8(2), apdu.u8(3)))
                assertEquals("800102840181", data.toHex())
                swOnly(mseOverride ?: 0x9000)
            }
            0x88 -> smData(fakeSignature(data))
            else -> swOnly(0x6D00)
        }
    }

    /** SW-only reply: the card still advances its SSC. */
    private fun swOnly(code: Int): ByteArray {
        inc()
        return sw(code)
    }

    /** 87 / 99 / 8E reply, split with 61xx when longer than 256 bytes. */
    private fun smData(plain: ByteArray): ByteArray {
        val enc = sessEnc!!
        inc()
        val ct = enc.cbcEncrypt(Iso9797.pad(plain), enc.ecbEncryptBlock(ssc))
        val t87 = SecureChannel.tlv(0x87, byteArrayOf(0x01) + ct)
        val t99 = SecureChannel.tlv(0x99, bytesOf(0x90, 0x00))
        val mac = Cmac.aesCmac(sessMac, Iso9797.pad(ssc + t87 + t99)).copyOf(8)
        pending = t87 + t99 + SecureChannel.tlv(0x8E, mac)
        return chunk(256)
    }

    private fun chunk(max: Int): ByteArray {
        val n = minOf(max, pending.size)
        val head = pending.copyOfRange(0, n)
        pending = pending.copyOfRange(n, pending.size)
        return if (pending.isEmpty()) head + ok() else head + bytesOf(0x61, minOf(pending.size, 0xFF) and 0xFF)
    }

    private fun ok() = sw(0x9000)

    private fun sw(code: Int) = bytesOf(code ushr 8, code and 0xFF)

    override fun close() {}
}
