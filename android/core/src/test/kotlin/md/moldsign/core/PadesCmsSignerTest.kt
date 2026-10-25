package md.moldsign.core

import java.io.File
import java.nio.charset.StandardCharsets.ISO_8859_1
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.PublicKey
import java.security.Signature
import java.security.cert.CertificateFactory
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test

class PadesCmsSignerTest {
    private val keys: KeyPair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
    private val certificate = TestCertificates.selfSigned(keys)
    private val clock = Clock.fixed(Instant.parse("2026-10-25T19:30:00Z"), ZoneOffset.ofHours(3))
    private val tsa = RecordingTsa()
    private val signer = PadesCmsSigner(tsa, clock)

    /** What the card does: raw RSA over a ready DigestInfo. */
    private val card = RawSigner { digestInfo ->
        Signature.getInstance("NONEwithRSA").run {
            initSign(keys.private)
            update(digestInfo)
            sign()
        }
    }

    private class RecordingTsa : TrustServices {
        val imprints = mutableListOf<ByteArray>()

        override fun timestamp(messageImprint: ByteArray): ByteArray {
            imprints += messageImprint
            return Der.seq(Der.oid(hexBytes("2A864886F70D010702")), Der.tlv(0xA0, Der.seq(Der.integer(3))))
        }

        override fun fetchCrl(url: String): ByteArray = TODO()

        override fun ocsp(certificateDer: ByteArray, issuerDer: ByteArray): ByteArray = TODO()
    }

    @Test
    fun signsAPdfWithAValidDetachedCms() {
        val pdf = TestDocuments.samplePdf()
        val signed = signer.sign(pdf, certificate, ChainCerts.chain, card)

        assertArrayEquals("the original bytes stay untouched (incremental update)", pdf, signed.copyOf(pdf.size))
        val signatures = signatures(signed)
        assertEquals(1, signatures.size)
        verify(signatures[0], keys.public, signed.size)
        assertEquals(1, tsa.imprints.size)
        assertArrayEquals("the RFC 3161 token covers sha256(signature)", Sha.sha256(signatures[0].signatureValue), tsa.imprints[0])
        writeForExternalTools("sample-signed.pdf", signed)
    }

    @Test
    fun embedsTheSignerAndTheCaChain() {
        val signed = signer.sign(TestDocuments.samplePdf(), certificate, ChainCerts.chain, card)
        val certs = signatures(signed)[0].signedData.children()[3].children().map { it.encoded }
        assertEquals(3, certs.size)
        assertArrayEquals(certificate, certs[0])
        assertArrayEquals(ChainCerts.mdQSign, certs[1])
        assertArrayEquals(ChainCerts.mdTrustCA, certs[2])
    }

    @Test
    fun writesTheMetadataTheMoldSignAppWrites() {
        val text = String(signer.sign(TestDocuments.samplePdf(), certificate, ChainCerts.chain, card), ISO_8859_1)
        assertTrue(text.contains("/SubFilter/ETSI.CAdES.detached"))
        assertTrue(text.contains("/M(D:20261025223000+03'00')"))
        assertTrue(text.contains("/Reason(MoldSign Signature) /Location(Moldova) /ContactInfo()"))
        assertTrue(text.contains("/T(Signature1)"))
        assertTrue(text.contains("/Extensions<</ESIC<</BaseVersion/1.7/ExtensionLevel 2>>>>"))
        assertTrue("widget points at the first page", text.contains("/P 3 0 R"))
        assertTrue(text.contains("/Prev "))
    }

    @Test
    fun xrefOffsetsPointAtTheAppendedObjects() {
        val pdf = TestDocuments.samplePdf()
        val signed = signer.sign(pdf, certificate, ChainCerts.chain, card)
        val text = String(signed, ISO_8859_1)
        val xref = text.lastIndexOf("\nxref\n") + 1
        assertEquals("startxref points at the new table", xref, text.substringAfterLast("startxref\n").substringBefore("\n").toInt())
        val entries = Regex("""(\d+) 1\n(\d{10}) 00000 n """).findAll(text.substring(xref)).toList()
        assertEquals(4, entries.size) // signature, AcroForm, field, catalog
        for (e in entries) {
            val num = e.groupValues[1]
            assertTrue("object $num", text.startsWith("$num 0 obj", e.groupValues[2].toInt()))
            assertTrue("offset past the original file", e.groupValues[2].toInt() >= pdf.size)
        }
    }

    @Test
    fun counterSigningKeepsTheFirstSignatureValid() {
        val first = signer.sign(TestDocuments.samplePdf(), certificate, ChainCerts.chain, card)
        val second = signer.sign(first, certificate, ChainCerts.chain, card)

        val signatures = signatures(second)
        assertEquals(2, signatures.size)
        verify(signatures[0], keys.public, first.size) // first signature covers its own revision only
        verify(signatures[1], keys.public, second.size)
        val text = String(second, ISO_8859_1)
        assertTrue(text.contains("/T(Signature2)"))
        assertEquals("one AcroForm, extended", 1, Regex("""/Fields\[6 0 R 9 0 R]""").findAll(text).count())
        writeForExternalTools("sample-countersigned.pdf", second)
    }

    @Test
    fun aTimestampFailureProducesNoDocument() {
        val failing = PadesCmsSigner(object : TrustServices by tsa {
            override fun timestamp(messageImprint: ByteArray): ByteArray = throw CardError.Network("MDQTSA")
        }, clock)
        try {
            failing.sign(TestDocuments.samplePdf(), certificate, ChainCerts.chain, card)
            throw AssertionError("expected CardError.Network")
        } catch (e: CardError.Network) {
            assertEquals("MDQTSA", e.service)
        }
    }

    @Test(expected = CardError.Format::class)
    fun rejectsAFileThatIsNotAPdf() {
        signer.sign("just text".toByteArray(), certificate, ChainCerts.chain, card)
    }

    @Test
    fun theBundledChainIsTheMoldovanPki() {
        val factory = CertificateFactory.getInstance("X.509")
        val subjects = ChainCerts.chain.map { (factory.generateCertificate(it.inputStream()) as java.security.cert.X509Certificate).subjectX500Principal.name }
        assertTrue(subjects[0], subjects[0].contains("CN=MDQSign"))
        assertTrue(subjects[1], subjects[1].contains("CN=mdtrustca"))
        assertArrayEquals(TestCertificates.mdQSign, ChainCerts.mdQSign)
    }

    @Test
    fun timestampRequestMatchesTheSwiftEncoding() {
        val request = TimestampRequest.build(ByteArray(32) { 0x11 })
        assertEquals("3039020101" + "3031" + "300D" + "0609608648016503040201" + "0500" + "0420" + "11".repeat(32) + "0101FF", request.toHex())
    }

    @Test
    fun timestampResponseYieldsTheToken() {
        val token = Der.seq(Der.oid(hexBytes("2A864886F70D010702")), Der.tlv(0xA0, Der.seq(Der.integer(3))))
        assertArrayEquals(token, TimestampRequest.token(Der.seq(Der.seq(Der.integer(0)), token)))
        assertArrayEquals(token, TimestampRequest.token(Der.seq(Der.seq(Der.integer(1)), token))) // grantedWithMods
    }

    @Test(expected = CardError.Network::class)
    fun timestampResponseThatIsNotGrantedIsRejected() {
        TimestampRequest.token(Der.seq(Der.seq(Der.integer(2))))
    }

    /** Live MDQTSA, like the Swift suite: `MSIGN_NETWORK_TESTS=1 ./gradlew :core:test`. Also writes a PDF with a real token. */
    @Test
    fun liveTimestampAuthorityAnswers() {
        assumeTrue(System.getenv("MSIGN_NETWORK_TESTS") == "1")
        val token = MdTrustServices().timestamp(Sha.sha256("signature".toByteArray()))
        val content = Der.read(token)
        assertEquals(0x30, content.tag)
        assertEquals("id-signedData", "2A864886F70D010702", content.children()[0].content.toHex())

        val signed = PadesCmsSigner(MdTrustServices(), clock).sign(TestDocuments.samplePdf(), certificate, ChainCerts.chain, card)
        verify(signatures(signed)[0], keys.public, signed.size)
        writeForExternalTools("live-tsa.pdf", signed)
    }

    // ---------------------------------------------------------------- independent verification

    private class Parsed(val range: List<Int>, val signedBytes: ByteArray, val cms: Der.Node) {
        val signedData: Der.Node get() = cms.children()[1].children()[0]
        private val signerInfo: List<Der.Node> get() = signedData.children()[4].children()[0].children()
        val signedAttributes: Der.Node get() = signerInfo[3]
        val signatureValue: ByteArray get() = signerInfo[5].content
        val unsignedAttributes: Der.Node get() = signerInfo[6]
    }

    private fun signatures(pdf: ByteArray): List<Parsed> {
        val text = String(pdf, ISO_8859_1)
        return Regex("""/ByteRange \[(\d+) (\d+) (\d+) (\d+) ]""").findAll(text).map { m ->
            val (a, b, c, d) = m.groupValues.drop(1).map { it.toInt() }
            assertEquals(0, a)
            assertEquals("the excluded range starts at '<'", '<'.code, pdf[b].toInt())
            assertEquals("and ends after '>'", '>'.code, pdf[c - 1].toInt())
            val hex = String(pdf, b + 1, c - b - 2, ISO_8859_1)
            assertEquals(37960, hex.length)
            val raw = hexBytes(hex)
            val cms = Der.read(raw)
            Parsed(listOf(a, b, c, d), pdf.copyOfRange(0, b) + pdf.copyOfRange(c, c + d), cms)
        }.toList()
    }

    private fun verify(sig: Parsed, publicKey: PublicKey, documentSize: Int) {
        assertTrue(sig.range[2] + sig.range[3] <= documentSize)
        val attrs = sig.signedAttributes.children().associate { attr ->
            val parts = attr.children()
            parts[0].content.toHex() to parts[1].children()[0]
        }
        assertEquals(
            "messageDigest = SHA-256 of the signed byte ranges",
            Sha.sha256(sig.signedBytes).toHex(),
            attrs.getValue("2A864886F70D010904").content.toHex(),
        )
        assertEquals("contentType = id-data", "2A864886F70D010701", attrs.getValue("2A864886F70D010903").content.toHex())
        // signingCertificateV2 (…9.16.2.47), nested SET{SEQ{SEQ{SEQ{OCTET}}}}: the v1 OID + missing nesting broke the portal for weeks
        val essCertId = attrs.getValue("2A864886F70D010910022F").children()[0].children()[0]
        assertEquals(Sha.sha256(certificate).toHex(), essCertId.children()[0].content.toHex())
        // the card signed SET(signedAttrs), not the [0]-tagged form
        val verifier = Signature.getInstance("SHA256withRSA").apply {
            initVerify(publicKey)
            update(Der.tlv(0x31, sig.signedAttributes.content))
        }
        assertTrue("RSA signature over the signed attributes", verifier.verify(sig.signatureValue))
        // unsigned [1]: id-aa-timeStampToken
        assertEquals("2A864886F70D010910020E", sig.unsignedAttributes.children()[0].children()[0].content.toHex())
    }

    // ---------------------------------------------------------------- fixtures

    /** For manual cross-checks with openssl / the Swift validator / iText (docs/02). */
    private fun writeForExternalTools(name: String, bytes: ByteArray) {
        val dir = File("build/pades-test").apply { mkdirs() }
        File(dir, name).writeBytes(bytes)
        File(dir, "signer.der").writeBytes(certificate)
    }

    private companion object {
        fun hexBytes(hex: String): ByteArray = hex.decodeHex()
    }
}
