package md.moldsign.core

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/** spec/vectors/card-crypto.json: KDF, external auth, response decode, session keys, CMAC, ISO 9797, DigestInfo. */
class CardCryptoVectorTest {
    private val v = SpecFiles.cardCrypto
    private val kdf = v.obj("kdf")
    private val kenc = kdf.hex("kenc")
    private val kmac = kdf.hex("kmac")

    @Test
    fun vectorFileVersion() {
        assertEquals(1L, (v as Map<*, *>)["version"])
    }

    @Test
    fun constantsMatchDriver() {
        val c = v.obj("constants")
        assertEquals(c.str("ias_aid"), CosmoXCard.IAS_AID.toHex())
        assertEquals(c.str("generic_adf"), CosmoXCard.GENERIC_ADF.toHex())
        assertEquals(c.str("mk_class"), CosmoXCard.MK_CLASS.toHex())
        assertEquals(c.str("rnd_ifd"), CosmoXCard.RND_IFD.toHex())
        assertEquals(c.str("sn_ifd"), CosmoXCard.SN_IFD.toHex())
        assertEquals(c.str("k_ifd"), CosmoXCard.K_IFD.toHex())
        assertEquals(c.str("mse_sm_apdu"), CosmoXCard.MSE_SM_APDU.toHex())
        assertEquals(c.str("mse_sign_data"), CosmoXCard.MSE_SIGN_DATA.toHex())
        assertEquals(c.str("pin_reference").toInt(16), CosmoXCard.PIN_REFERENCE)
    }

    @Test
    fun kdf() {
        val seed = kdf.str("seed_ascii").toByteArray(Charsets.US_ASCII)
        val serial = kdf.str("serial_ascii").toByteArray(Charsets.US_ASCII)
        val (enc, mac) = CosmoXCard.deriveAdminKeys(seed, serial)
        assertEquals(kdf.str("kenc"), enc.toHex())
        assertEquals(kdf.str("kmac"), mac.toHex())
    }

    @Test
    fun externalAuthCiphertextAndCmac() {
        val ea = v.obj("external_auth")
        val (ct, mac) = CosmoXCard.externalAuthPayload(
            kenc, kmac, ea.hex("rnd_icc"), ea.str("sn_icc_ascii").toByteArray(Charsets.US_ASCII),
        )
        assertEquals(ea.str("ciphertext"), ct.toHex())
        assertEquals(ea.str("cmac"), mac.toHex())
    }

    @Test
    fun responseDecode() {
        val rd = v.obj("response_decode")
        val resp = rd.hex("response")
        assertEquals(96, resp.size)
        val ct = resp.copyOfRange(0, 80)
        assertEquals(resp.copyOfRange(80, 96).toHex(), Cmac.aesCmac(kmac, ct).toHex())
        val plain = Aes(kenc).cbcDecrypt(ct, Aes.ZERO_IV)
        assertEquals(rd.str("challenge"), plain.copyOfRange(0, 16).toHex())
        // The driver's combined path accepts the same response (MAC verified, channel built).
        CosmoXCard.decodeAuthResponse(kenc, kmac, resp)
    }

    @Test
    fun sessionKeys() {
        val sk = v.obj("session_keys")
        val (enc, mac) = CosmoXCard.deriveSessionKeys(sk.hex("k_icc"))
        assertEquals(sk.str("sess_enc"), enc.toHex())
        assertEquals(sk.str("sess_mac"), mac.toHex())
    }

    @Test
    fun ivForInitialSsc() {
        val sm = v.obj("sm")
        assertEquals(sm.str("iv_for_ssc_initial"), Aes(sm.hex("sess_enc")).ecbEncryptBlock(sm.hex("ssc_initial")).toHex())
    }

    @Test
    fun smUnwrap() {
        val sm = v.obj("sm")
        val u = sm.obj("unwrap")
        val ch = SecureChannel(sm.hex("sess_enc"), sm.hex("sess_mac"), sm.hex("ssc_initial"))
        ch.wrap(u.hex("command_before"))
        val resp = ch.unwrap(u.hex("response"))
        assertEquals(u.str("data"), resp.data.toHex())
        assertEquals(u.str("sw").toInt(16), resp.sw)
    }

    @Test(expected = CardError.SmOutOfSync::class)
    fun smUnwrapRejectsTamperedMac() {
        val sm = v.obj("sm")
        val u = sm.obj("unwrap")
        val ch = SecureChannel(sm.hex("sess_enc"), sm.hex("sess_mac"), sm.hex("ssc_initial"))
        ch.wrap(u.hex("command_before"))
        val tampered = u.hex("response").also { it[it.size - 3] = (it[it.size - 3].toInt() xor 1).toByte() }
        ch.unwrap(tampered)
    }

    @Test(expected = CardError.SmOutOfSync::class)
    fun smUnwrapWithWrongSscFails() {
        // Skipping the command's SSC step (the 6988 failure mode) must surface as SmOutOfSync.
        val sm = v.obj("sm")
        val ch = SecureChannel(sm.hex("sess_enc"), sm.hex("sess_mac"), sm.hex("ssc_initial"))
        ch.unwrap(sm.obj("unwrap").hex("response"))
    }

    @Test
    fun iso9797() {
        for (case in v.list("iso9797")) {
            val input = case.hex("input")
            val padded = Iso9797.pad(input)
            assertEquals("pad(${case.str("input")})", case.str("padded"), padded.toHex())
            assertArrayEquals("unpad(${case.str("padded")})", input, Iso9797.unpad(padded))
        }
    }

    @Test
    fun digestInfo() {
        val di = v.obj("digest_info")
        assertEquals(di.str("digest_info"), DigestInfo.sha256(di.str("message_ascii").toByteArray(Charsets.US_ASCII)).toHex())
    }

    @Test
    fun sscIncrementCarries() {
        val ch = SecureChannel(ByteArray(32), ByteArray(32), "000000000000000000000000000000FF".decodeHex())
        assertEquals("00000000000000000000000000000100", ch.incrementSsc().toHex())
        val wrap = SecureChannel(ByteArray(32), ByteArray(32), "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF".decodeHex())
        assertEquals("00000000000000000000000000000000", wrap.incrementSsc().toHex())
    }
}

/** Every `sm.wrap` case, each from a FRESH channel at `ssc_initial`. */
@RunWith(Parameterized::class)
class SmWrapVectorTest(private val name: String, private val apdu: String, private val wrapped: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<Array<Any>> = SpecFiles.cardCrypto.obj("sm").list("wrap").map {
            arrayOf<Any>(it.str("name"), it.str("apdu"), it.str("wrapped"))
        }
    }

    @Test
    fun wrap() {
        val sm = SpecFiles.cardCrypto.obj("sm")
        val ch = SecureChannel(sm.hex("sess_enc"), sm.hex("sess_mac"), sm.hex("ssc_initial"))
        assertEquals(name, wrapped, ch.wrap(apdu.decodeHex()).toHex())
    }
}

/** NIST SP 800-38B AES-256 CMAC examples, including the empty message the C shim gets wrong. */
@RunWith(Parameterized::class)
class CmacVectorTest(private val message: String, private val tag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "len={index}")
        fun cases(): List<Array<Any>> = SpecFiles.cardCrypto.obj("cmac").list("cases").map {
            arrayOf<Any>(it.str("message"), it.str("tag"))
        }
    }

    @Test
    fun tag() {
        val key = SpecFiles.cardCrypto.obj("cmac").hex("key")
        assertEquals("CMAC(${message.length / 2} B)", tag, Cmac.aesCmac(key, message.decodeHex()).toHex())
    }
}
