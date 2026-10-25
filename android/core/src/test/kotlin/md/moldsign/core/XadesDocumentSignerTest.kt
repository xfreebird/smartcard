package md.moldsign.core

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.w3c.dom.Element
import java.io.ByteArrayInputStream
import java.io.File
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.Base64
import javax.xml.crypto.KeySelector
import javax.xml.crypto.OctetStreamData
import javax.xml.crypto.dsig.CanonicalizationMethod
import javax.xml.crypto.dsig.DigestMethod
import javax.xml.crypto.dsig.SignatureMethod
import javax.xml.crypto.dsig.spec.C14NMethodParameterSpec
import javax.xml.crypto.dsig.Reference
import javax.xml.crypto.dsig.XMLSignature
import javax.xml.crypto.dsig.XMLSignatureFactory
import javax.xml.crypto.dsig.dom.DOMValidateContext
import javax.xml.crypto.dsig.dom.DOMSignContext
import javax.xml.parsers.DocumentBuilderFactory

/**
 * XAdES BES / T / C (docs/03). The signatures are validated by the JDK's own XML-DSig engine (an independent
 * canonicalizer and reference resolver), so a wrong c14n or digest in the builder fails here.
 */
class XadesDocumentSignerTest {
    private val keys: KeyPair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
    private val certificate = TestCertificates.selfSigned(keys, "Ștefan Test")
    private val clock = Clock.fixed(Instant.parse("2026-10-25T19:30:00Z"), ZoneOffset.ofHours(2))
    private val document = Document("contract.xml", "<contract>fictional</contract>".toByteArray())

    private val digestInfos = mutableListOf<ByteArray>()
    private val card = RawSigner { digestInfo ->
        digestInfos += digestInfo
        Signature.getInstance("NONEwithRSA").run {
            initSign(keys.private)
            update(digestInfo)
            sign()
        }
    }

    private class StubTrust : TrustServices {
        val imprints = mutableListOf<ByteArray>()
        val crlUrls = mutableListOf<String>()
        val ocspCalls = mutableListOf<Pair<ByteArray, ByteArray>>()
        val crl = buildCrl()
        val ocsp = buildOcsp()

        override fun timestamp(messageImprint: ByteArray): ByteArray {
            imprints += messageImprint
            return Der.seq(Der.oid("2A864886F70D010702".decodeHex()), Der.tlv(0xA0, Der.seq(Der.integer(3))))
        }

        override fun fetchCrl(url: String): ByteArray {
            crlUrls += url
            return crl
        }

        override fun ocsp(certificateDer: ByteArray, issuerDer: ByteArray): ByteArray {
            ocspCalls += certificateDer to issuerDer
            return ocsp
        }
    }

    private val trust = StubTrust()
    private val signer = XadesDocumentSigner(trust, clock)

    private fun sign(level: XadesLevel, packaging: XadesPackaging = XadesPackaging.Detached, digest: XadesDigest = XadesDigest.SHA256) =
        signer.sign(listOf(document), level, packaging, certificate, listOf(TestCertificates.mdQSign, TestCertificates.mdTrustCa), card, digest)

    @Test
    fun besDetachedValidatesWithTheJdkEngine() {
        val xml = sign(XadesLevel.BES)
        val text = String(xml, Charsets.UTF_8)

        val result = validate(xml, mapOf("contract.xml" to document.bytes))

        assertTrue(result.toString(), result.values.all { it })
        assertEquals(setOf("file:/contract.xml", "#SignedProperties-${id(text, "SignedProperties")}"), result.keys - "signature")
        assertTrue(text.startsWith("""<?xml version="1.0" encoding="UTF-8" standalone="no"?><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Id="Signature-"""))
        assertFalse("BES carries no unsigned properties", text.contains("UnsignedProperties"))
        // the vendor's escaping: Ș is the UTF-8 bytes C8 98, written \C8\98; the issuer name is in RFC 2253 order
        assertTrue(text, text.contains("<ds:X509IssuerName>CN=\\C8\\98tefan Test,C=MD</ds:X509IssuerName><ds:X509SerialNumber>74565</ds:X509SerialNumber>"))
        assertTrue(text.contains("<xades:SigningTime>2026-10-25T21:30:00+02:00</xades:SigningTime>"))
        assertEquals("one signature, SHA-256 DigestInfo", 1, digestInfos.size)
        assertArrayEquals(DigestInfo.SHA256_PREFIX, digestInfos[0].copyOf(DigestInfo.SHA256_PREFIX.size))
        write("bes-detached", xml)
    }

    @Test
    fun sha1RequestedByThePortalUsesSha1EverywhereButTheTimestamp() {
        val xml = sign(XadesLevel.T, digest = XadesDigest.SHA1)
        val text = String(xml, Charsets.UTF_8)

        val result = validate(xml, mapOf("contract.xml" to document.bytes), secure = false)

        assertTrue(result.toString(), result.values.all { it })
        assertTrue(text.contains("""<ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1">"""))
        assertFalse(text.contains("xmlenc#sha256"))
        assertEquals("SHA-1 DigestInfo is 35 bytes", 35, digestInfos.single().size)
        assertEquals(32, trust.imprints.single().size)
        assertEquals(XadesDigest.SHA1, XadesDigest.fromRequested("SHA-1"))
        assertEquals(XadesDigest.SHA1, XadesDigest.fromRequested("sha1"))
        assertEquals(XadesDigest.SHA256, XadesDigest.fromRequested(null))
        assertEquals(XadesDigest.SHA256, XadesDigest.fromRequested("SHA256"))
    }

    @Test
    fun timestampCoversTheCanonicalSignatureValue() {
        val xml = sign(XadesLevel.T)
        val text = String(xml, Charsets.UTF_8)

        val result = validate(xml, mapOf("contract.xml" to document.bytes))

        assertTrue(result.toString(), result.values.all { it })
        assertTrue(text.contains("<xades:UnsignedProperties><xades:UnsignedSignatureProperties><xades:SignatureTimeStamp"))
        assertFalse(text.contains("CompleteCertificateRefs"))
        // the JDK's own same-document canonicalization of the SignatureValue element is what the TSA was asked to stamp
        assertArrayEquals(jdkDigest(xml, "SignatureValue-${id(text, "SignatureValue")}"), trust.imprints.single())
        write("t-detached", xml)
    }

    @Test
    fun completeRefsListTheChainAndTheRevocationData() {
        val xml = sign(XadesLevel.C)
        val text = String(xml, Charsets.UTF_8)

        val result = validate(xml, mapOf("contract.xml" to document.bytes))

        assertTrue(result.toString(), result.values.all { it })
        // signer + MDQSign CA; the self-signed root is not referenced
        assertEquals(2, Regex("<xades:Cert><xades:CertDigest>").findAll(text.substringAfter("<xades:CertRefs>")).count())
        assertTrue(text.contains(MDQSIGN_ISSUER_NAMED))
        assertTrue(text.contains("<ds:X509SerialNumber>$MDQSIGN_SERIAL</ds:X509SerialNumber>"))
        // CRL of the CA from its CRL distribution point; the self-signed signer publishes none
        assertEquals(listOf("http://pki.md/crl/mdtrustca.crl"), trust.crlUrls)
        assertTrue(text.contains("""<xades:CRLIdentifier URI="http://pki.md/crl/mdtrustca.crl"><xades:Issuer>$MDTRUSTCA_NAMED</xades:Issuer>"""))
        assertTrue(text.contains("<xades:Number>4660</xades:Number>"))
        assertTrue(text.contains("<xades:IssueTime>2026-10-24T12:00:00+02:00</xades:IssueTime>"))
        assertTrue(text.contains("""<ds:DigestValue>${Base64.getEncoder().encodeToString(Sha.sha256(trust.crl))}</ds:DigestValue>"""))
        // vendor quirk: the same OCSP answer about the signer, once per referenced certificate
        assertEquals(1, trust.ocspCalls.size)
        assertArrayEquals(certificate, trust.ocspCalls[0].first)
        assertArrayEquals(TestCertificates.mdQSign, trust.ocspCalls[0].second)
        assertEquals(2, Regex("<xades:OCSPRef>").findAll(text).count())
        assertTrue(text.contains("""<xades:OCSPIdentifier URI="http://mdqsign.ocsp.pki.md"><xades:ResponderID><xades:ByName>$MDTRUSTCA_NAMED</xades:ByName></xades:ResponderID><xades:ProducedAt>2026-10-25T21:00:00+02:00</xades:ProducedAt>"""))
        assertTrue(text.contains("SignatureTimeStamp"))
        write("c-detached", xml)
    }

    @Test
    fun aFailingRevocationServiceFailsTheSignatureInsteadOfDroppingTheRefs() {
        val failing = object : TrustServices by trust {
            override fun fetchCrl(url: String): ByteArray = throw CardError.Network("CRL")
        }
        try {
            XadesDocumentSigner(failing, clock).sign(
                listOf(document), XadesLevel.C, XadesPackaging.Detached, certificate, listOf(TestCertificates.mdQSign), card,
            )
            fail("expected a network error")
        } catch (e: CardError.Network) {
            assertEquals("CRL", e.service)
        }
    }

    @Test
    fun envelopingEmbedsTheContentAndValidates() {
        val xml = sign(XadesLevel.BES, XadesPackaging.Enveloping)
        val text = String(xml, Charsets.UTF_8)

        val result = validate(xml, emptyMap())

        assertTrue(result.toString(), result.values.all { it })
        assertTrue(text.contains("http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments"))
        val encoded = Base64.getEncoder().encodeToString(document.bytes)
        assertTrue(text.contains("""Encoding="UTF-8" Id="FileObject-""") && text.contains(">$encoded</ds:Object>"))
        assertFalse(text.contains("file:/"))
        write("bes-enveloping", xml)
    }

    @Test
    fun ocspRequestMatchesOpensslByteForByte() {
        // openssl ocsp -issuer mdtrustca.pem -cert mdqsign.pem -reqout … -no_nonce
        val expected = "304f304d304b30493047300906052b0e03021a05000414fabba66d3a161f4f2ccee89a8bd7409d50688ccd04146d3687be0a5d773de3f77195158d0368b8b06d78020e40000000103001db5ed3a4edb02b"
        assertEquals(expected, Revocation.ocspRequest(TestCertificates.mdQSign, TestCertificates.mdTrustCa).toHex().lowercase())
    }

    @Test
    fun vendorNamesAndSerialsMatchOpenssl() {
        val parts = CertParts.parse(TestCertificates.mdQSign)
        // openssl x509 -nameopt RFC2253,esc_msb
        assertEquals(MDQSIGN_ISSUER_NAMED, VendorNames.rfc2253(parts.issuer, namedOrgId = true))
        assertEquals(MDQSIGN_ISSUER_NAMED.replace("organizationIdentifier=", "2.5.4.97="), VendorNames.rfc2253(parts.issuer, namedOrgId = false))
        assertEquals(MDQSIGN_SERIAL, parts.serial.toString())
        assertFalse(parts.isSelfSigned)
        assertTrue(CertParts.parse(TestCertificates.mdTrustCa).isSelfSigned)
        assertEquals("http://pki.md/crl/mdtrustca.crl", Revocation.crlUrl(TestCertificates.mdQSign))
        assertEquals("2026-10-25T21:30:00+02:00", VendorNames.iso8601(Instant.parse("2026-10-25T19:30:00Z"), ZoneOffset.ofHours(2)))
        assertEquals("2026-10-25T21:00:00+02:00", VendorNames.time(Der.read(Der.tlv(0x17, "261025190000Z".toByteArray())), ZoneOffset.ofHours(2)))
        assertEquals("2000-01-01T01:59:59+02:00", VendorNames.time(Der.read(Der.tlv(0x17, "991231235959Z".toByteArray())), ZoneOffset.ofHours(2)))
        assertEquals("2026-10-25T21:00:00+02:00", VendorNames.time(Der.read(Der.tlv(0x18, "20261025190000Z".toByteArray())), ZoneOffset.ofHours(2)))
    }

    // ------------------------------------------------------------------ JDK XML-DSig validation

    private fun parse(xml: ByteArray) = DocumentBuilderFactory.newInstance().apply { isNamespaceAware = true }
        .newDocumentBuilder().parse(ByteArrayInputStream(xml))

    private fun registerIds(el: Element) {
        if (el.hasAttribute("Id")) el.setIdAttribute("Id", true)
        val children = el.childNodes
        for (i in 0 until children.length) (children.item(i) as? Element)?.let(::registerIds)
    }

    /** `signature` plus one entry per reference (by URI) → valid. */
    private fun validate(xml: ByteArray, files: Map<String, ByteArray>, secure: Boolean = true): Map<String, Boolean> {
        val doc = parse(xml)
        val element = doc.getElementsByTagNameNS(XMLSignature.XMLNS, "Signature").item(0) as Element
        registerIds(doc.documentElement)
        val cert = CertificateFactory.getInstance("X.509").generateCertificate(
            ByteArrayInputStream(
                Base64.getMimeDecoder().decode(element.getElementsByTagNameNS(XMLSignature.XMLNS, "X509Certificate").item(0).textContent.trim()),
            ),
        ) as X509Certificate
        val factory = XMLSignatureFactory.getInstance("DOM")
        val context = DOMValidateContext(KeySelector.singletonKeySelector(cert.publicKey), element)
        context.setProperty("org.jcp.xml.dsig.secureValidation", secure)
        val standard = factory.uriDereferencer
        context.uriDereferencer = javax.xml.crypto.URIDereferencer { reference, ctx ->
            val bytes = if (reference.uri.startsWith("file:/")) files[reference.uri.removePrefix("file:/")] else null
            if (bytes != null) OctetStreamData(ByteArrayInputStream(bytes), reference.uri, null) else standard.dereference(reference, ctx)
        }
        val signature = factory.unmarshalXMLSignature(context)
        val out = linkedMapOf("signature" to signature.validate(context))
        for (reference in signature.signedInfo.references) out[(reference as Reference).uri] = reference.validate(context)
        return out
    }

    /** SHA-256 of the element as the JDK canonicalizes a same-document reference to it (inclusive C14N). */
    private fun jdkDigest(xml: ByteArray, elementId: String): ByteArray {
        val doc = parse(xml)
        registerIds(doc.documentElement)
        val factory = XMLSignatureFactory.getInstance("DOM")
        val reference = factory.newReference("#$elementId", factory.newDigestMethod(DigestMethod.SHA256, null))
        val signedInfo = factory.newSignedInfo(
            factory.newCanonicalizationMethod(CanonicalizationMethod.INCLUSIVE, null as C14NMethodParameterSpec?),
            factory.newSignatureMethod(SignatureMethod.RSA_SHA256, null),
            listOf(reference),
        )
        val signature = factory.newXMLSignature(signedInfo, null)
        signature.sign(DOMSignContext(keys.private, doc.documentElement))
        return (signature.signedInfo.references.single() as Reference).digestValue
    }

    private fun id(xml: String, element: String) = Regex("""Id="$element-([0-9A-F-]+)"""").find(xml)!!.groupValues[1]

    private fun write(name: String, xml: ByteArray) {
        val dir = File("build/xades-test").apply { mkdirs() }
        File(dir, "$name.xml").writeBytes(xml)
        File(dir, document.name).writeBytes(document.bytes)
    }

    private companion object {
        const val MDQSIGN_SERIAL = "1298074214710150348378953499914283"
        const val MDTRUSTCA_NAMED =
            "organizationIdentifier=NTRMD-1003600096694,CN=mdtrustca,O=IP Serviciul Tehnologia Informa\\C8\\9Biei \\C5\\9Fi Securitate Cibernetic\\C4\\83,L=Chi\\C8\\99in\\C4\\83u,C=MD"
        const val MDQSIGN_ISSUER_NAMED = MDTRUSTCA_NAMED

        /** A CertificateList with just what the reference needs: issuer, thisUpdate and the CRL number 0x1234. */
        fun buildCrl(): ByteArray {
            val issuer = CertParts.parse(TestCertificates.mdTrustCa).subject
            val algorithm = Der.seq(Der.oid("2A864886F70D01010B".decodeHex()), Der.NULL)
            val number = Der.seq(Der.seq(Der.oid("551D14".decodeHex()), Der.octetString(Der.tlv(0x02, byteArrayOf(0x12, 0x34)))))
            val tbs = Der.seq(
                Der.integer(1), algorithm, issuer,
                Der.tlv(0x17, "261024100000Z".toByteArray()), Der.tlv(0x17, "261031100000Z".toByteArray()),
                Der.tlv(0xA0, number),
            )
            return Der.seq(tbs, algorithm, Der.tlv(0x03, byteArrayOf(0, 1, 2, 3)))
        }

        /** An OCSPResponse (status successful) whose BasicOCSPResponse names mdtrustca as responder, produced 19:00Z. */
        fun buildOcsp(): ByteArray {
            val responder = Der.tlv(0xA1, CertParts.parse(TestCertificates.mdTrustCa).subject)
            val data = Der.seq(responder, Der.tlv(0x18, "20261025190000Z".toByteArray()), Der.seq())
            val algorithm = Der.seq(Der.oid("2A864886F70D01010B".decodeHex()), Der.NULL)
            val basic = Der.seq(data, algorithm, Der.tlv(0x03, byteArrayOf(0, 1, 2, 3)))
            val bytes = Der.seq(Der.oid("2B0601050507300101".decodeHex()), Der.octetString(basic))
            return Der.seq(Der.tlv(0x0A, byteArrayOf(0)), Der.tlv(0xA0, bytes))
        }
    }
}
