package md.moldsign.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.Signature
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset

/**
 * The offline validator against signatures made by this app's signers (software key standing in for the card) and
 * against tampered copies. The chain check uses a test CA / root in place of the Moldovan ones.
 */
class OfflineValidatorTest {
    private fun keyPair(): KeyPair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()

    private val rootKeys = keyPair()
    private val caKeys = keyPair()
    private val leafKeys = keyPair()
    private val root = TestCertificates.selfSigned(rootKeys, "Test Root")
    private val ca = TestCertificates.issued(caKeys, "Test CA", rootKeys, "Test Root")
    private val leaf = TestCertificates.issued(leafKeys, "Ștefan Test", caKeys, "Test CA")
    private val selfSigned = TestCertificates.selfSigned(leafKeys, "Ștefan Test")
    private val validator = OfflineValidator(issuingCa = ca, rootCa = root)

    private val clock = Clock.fixed(Instant.parse("2026-10-25T19:30:00Z"), ZoneOffset.ofHours(2))
    private val card = RawSigner { digestInfo ->
        Signature.getInstance("NONEwithRSA").run {
            initSign(leafKeys.private)
            update(digestInfo)
            sign()
        }
    }

    /** A TSA that returns a well-formed RFC 3161 token whose imprint is [imprintOf] the request. */
    private class FakeTsa(private val imprintOf: (ByteArray) -> ByteArray = { it }) : TrustServices {
        override fun timestamp(messageImprint: ByteArray): ByteArray {
            val tstInfo = Der.seq(
                Der.integer(1), Der.oid("2A0304".decodeHex()),
                Der.seq(Der.seq(Der.oid("608648016503040201".decodeHex()), Der.NULL), Der.octetString(imprintOf(messageImprint))),
                Der.integer(7), Der.tlv(0x18, "20261025193005Z".toByteArray()),
            )
            val signedData = Der.seq(
                Der.integer(3), Der.set(), Der.seq(Der.oid("2A864886F70D0109100104".decodeHex()), Der.tlv(0xA0, Der.octetString(tstInfo))), Der.set(),
            )
            return Der.seq(Der.oid("2A864886F70D010702".decodeHex()), Der.tlv(0xA0, signedData))
        }

        override fun fetchCrl(url: String): ByteArray = TODO()

        override fun ocsp(certificateDer: ByteArray, issuerDer: ByteArray): ByteArray = TODO()
    }

    private val tsa = FakeTsa()
    private val pdf = TestDocuments.samplePdf()
    private fun signPdf(input: ByteArray = pdf, tsa: TrustServices = this.tsa) = PadesCmsSigner(tsa, clock).sign(input, leaf, listOf(ca, root), card)

    // ------------------------------------------------------------------ PAdES

    @Test
    fun aFreshPadesSignatureIsValidTimestampedAndChained() {
        val reports = validator.verifyPdf(signPdf())

        val r = reports.single()
        assertTrue(r.details.toString(), r.integrityOk && r.signatureOk)
        assertEquals(true, r.chainOk)
        assertEquals("Ștefan Test", r.signerName)
        assertEquals("PAdES-B-T", r.level)
        assertEquals(Instant.parse("2026-10-25T19:30:00Z"), r.signingTime?.toInstant())
        assertEquals(Instant.parse("2026-10-25T19:30:05Z"), r.timestampTime?.toInstant())
        assertEquals(emptyList<String>(), r.details)
    }

    @Test
    fun aChainThatDoesNotLeadToTheTrustRootIsReportedAsUntrusted() {
        val signed = PadesCmsSigner(tsa, clock).sign(pdf, selfSigned, emptyList(), card)

        val r = validator.verifyPdf(signed).single()

        assertTrue(r.integrityOk && r.signatureOk)
        assertEquals(false, r.chainOk)
    }

    @Test
    fun changingTheSignedBytesBreaksIntegrity() {
        val signed = signPdf()
        val tampered = signed.copyOf().also { it[10] = (it[10] + 1).toByte() } // inside the first ByteRange part

        val r = validator.verifyPdf(tampered).single()

        assertFalse(r.integrityOk)
        assertTrue("the CMS itself is untouched", r.signatureOk)
    }

    @Test
    fun dataAppendedAfterTheSignatureIsNotCovered() {
        val signed = signPdf() + "1 0 obj\n<<>>\nendobj\n".toByteArray()

        val r = validator.verifyPdf(signed).single()

        assertFalse(r.integrityOk)
        assertTrue(r.details.toString(), r.details.any { "not covered" in it })
    }

    @Test
    fun aCorruptedSignatureValueFailsTheRsaCheck() {
        val text = String(signPdf(), Charsets.ISO_8859_1)
        val contents = Regex("""/Contents\s*<([0-9a-fA-F]+)>""").find(text)!!
        val hex = contents.groupValues[1]
        val at = hex.indexOf(Cms.parse(hex.decodeHex()).signature.toHex().take(64), ignoreCase = true)
        assertTrue(at > 0)
        val flipped = hex.substring(0, at + 10) + (if (hex[at + 10] == '0') '1' else '0') + hex.substring(at + 11)
        val tampered = text.replace(hex, flipped).toByteArray(Charsets.ISO_8859_1)

        val r = validator.verifyPdf(tampered).single()

        assertTrue("the document is unchanged", r.integrityOk)
        assertFalse(r.signatureOk)
    }

    @Test
    fun aTimestampOverSomethingElseIsNotCounted() {
        val signed = signPdf(tsa = FakeTsa { Sha.sha256(it) }) // stamps a hash of the imprint, not the imprint

        val r = validator.verifyPdf(signed).single()

        assertTrue(r.integrityOk && r.signatureOk)
        assertNull(r.timestampTime)
        assertEquals("PAdES-B-B", r.level)
        assertTrue(r.details.any { "time-stamp does not cover" in it })
    }

    @Test
    fun counterSigningKeepsBothSignaturesValid() {
        val reports = validator.verifyPdf(signPdf(signPdf()))

        assertEquals(2, reports.size)
        assertTrue(reports.toString(), reports.all { it.integrityOk && it.signatureOk && it.chainOk == true })
    }

    @Test
    fun aFileWithoutSignaturesHasNoReports() {
        assertEquals(emptyList<ValidationReport>(), validator.verifyPdf(pdf))
    }

    @Test
    fun aByteRangeThatDoesNotEncloseTheContentsIsUnreadable() {
        val broken = String(signPdf(), Charsets.ISO_8859_1).replace(Regex("""/ByteRange\s*\[\s*0 """), "/ByteRange [ 1 ")

        val r = validator.verifyPdf(broken.toByteArray(Charsets.ISO_8859_1)).single()

        assertFalse(r.integrityOk)
    }

    // ------------------------------------------------------------------ XAdES

    private val document = Document("contract.xml", "<contract>fictional</contract>".toByteArray())
    private fun xades(level: XadesLevel, packaging: XadesPackaging = XadesPackaging.Detached, digest: XadesDigest = XadesDigest.SHA256, tsa: TrustServices = this.tsa) =
        XadesDocumentSigner(tsa, clock).sign(listOf(document), level, packaging, leaf, emptyList(), card, digest)

    @Test
    fun xadesLevelsValidateAndAreNamed() {
        for ((level, name) in listOf(XadesLevel.BES to "XAdES-BES", XadesLevel.T to "XAdES-T")) {
            val r = validator.verifyXades(xades(level), listOf(document)).single()
            assertTrue("$name ${r.details}", r.integrityOk && r.signatureOk)
            assertEquals(name, r.level)
            assertEquals(true, r.chainOk)
            assertEquals("Ștefan Test", r.signerName)
            assertEquals(Instant.parse("2026-10-25T19:30:00Z"), r.signingTime?.toInstant())
            assertEquals(level != XadesLevel.BES, r.timestampTime != null)
        }
    }

    @Test
    fun sha1SignaturesAndEnvelopingValidate() {
        val sha1 = validator.verifyXades(xades(XadesLevel.T, digest = XadesDigest.SHA1), listOf(document)).single()
        assertTrue(sha1.details.toString(), sha1.integrityOk && sha1.signatureOk && sha1.timestampTime != null)

        val enveloping = validator.verifyXades(xades(XadesLevel.BES, XadesPackaging.Enveloping), emptyList()).single()
        assertTrue(enveloping.details.toString(), enveloping.integrityOk && enveloping.signatureOk)
        assertEquals(emptyList<String>(), enveloping.missingDocuments)
    }

    @Test
    fun aDetachedSignatureNeedsItsDocument() {
        val signed = xades(XadesLevel.BES)

        val missing = validator.verifyXades(signed, emptyList()).single()
        assertFalse(missing.integrityOk)
        assertTrue("the signature itself is fine", missing.signatureOk)
        assertEquals(listOf("contract.xml"), missing.missingDocuments)

        val changed = validator.verifyXades(signed, listOf(Document("contract.xml", "<contract>changed</contract>".toByteArray()))).single()
        assertFalse(changed.integrityOk)
        assertEquals(emptyList<String>(), changed.missingDocuments)
    }

    @Test
    fun tamperedSignedPropertiesAndSignatureValueAreCaught() {
        val text = String(xades(XadesLevel.BES), Charsets.UTF_8)

        val propsChanged = text.replace("<xades:MimeType>application/octet-stream", "<xades:MimeType>text/plain")
        val r1 = validator.verifyXades(propsChanged.toByteArray(), listOf(document)).single()
        assertFalse(r1.integrityOk)

        val value = Regex("""(<ds:SignatureValue Id="[^"]+">)(.{10})""").find(text)!!
        val flipped = text.replace(value.value, value.groupValues[1] + (if (value.groupValues[2][0] == 'A') "B" else "A") + value.groupValues[2].drop(1))
        val r2 = validator.verifyXades(flipped.toByteArray(), listOf(document)).single()
        assertTrue(r2.integrityOk)
        assertFalse(r2.signatureOk)
    }

    @Test
    fun aTimestampOverAnotherValueIsNotCountedForXades() {
        val r = validator.verifyXades(xades(XadesLevel.T, tsa = FakeTsa { Sha.sha256(it) }), listOf(document)).single()

        assertTrue(r.integrityOk && r.signatureOk)
        assertNull(r.timestampTime)
        assertEquals("XAdES-BES", r.level)
        assertNotNull(r.details.singleOrNull { "does not cover" in it })
    }

    @Test
    fun somethingThatIsNotAnXmlSignatureHasNoReports() {
        assertEquals(emptyList<ValidationReport>(), validator.verifyXades("<a/>".toByteArray(), emptyList()))
        assertEquals(emptyList<ValidationReport>(), validator.verifyXades(ByteArray(0), emptyList()))
    }

    @Test
    fun theVerdictFollowsTheReports() {
        fun report(integrity: Boolean = true, signature: Boolean = true, chain: Boolean? = true, missing: List<String> = emptyList()) =
            ValidationReport("A", null, null, "PAdES-B-T", integrity, signature, chain, missingDocuments = missing)

        assertEquals(Verdict.NoSignature, Verdict.of(emptyList()))
        assertEquals(Verdict.Valid, Verdict.of(listOf(report(), report())))
        assertEquals(Verdict.Invalid, Verdict.of(listOf(report(), report(integrity = false))))
        assertEquals(Verdict.Invalid, Verdict.of(listOf(report(signature = false))))
        assertEquals(Verdict.Unconfirmed, Verdict.of(listOf(report(chain = false))))
        assertEquals(Verdict.Unconfirmed, Verdict.of(listOf(report(chain = null))))
        assertEquals("a missing document is not a change", Verdict.Unconfirmed, Verdict.of(listOf(report(integrity = false, missing = listOf("a.xml")))))
        assertEquals("a bad signature wins", Verdict.Invalid, Verdict.of(listOf(report(signature = false, missing = listOf("a.xml")))))
    }

    @Test
    fun theSigningServiceVerifiesBothKindsThroughTheValidator() {
        val service = CardSigningService(
            TransportProvider { error("no card needed") }, kotlinx.coroutines.flow.MutableStateFlow(ReaderState.NoReader),
            validator = validator,
        )

        assertEquals(1, service.verify(Document("a.pdf", signPdf())).size)
        assertEquals(1, service.verify(Document("a.xml", xades(XadesLevel.BES)), listOf(document)).size)
    }
}
