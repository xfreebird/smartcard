package md.moldsign.core

import java.time.Clock
import java.time.ZoneId
import java.util.Base64
import java.util.UUID

/** Digest of the XAdES references, SignedProperties, certificate digest and signature method (docs/03, R-11). */
enum class XadesDigest(val digestUri: String, val signatureUri: String) {
    SHA256("http://www.w3.org/2001/04/xmlenc#sha256", "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"),
    SHA1("http://www.w3.org/2000/09/xmldsig#sha1", "http://www.w3.org/2000/09/xmldsig#rsa-sha1"),
    ;

    fun hash(data: ByteArray): ByteArray = if (this == SHA1) Sha.sha1(data) else Sha.sha256(data)

    /** DigestInfo over hash(data): the input of the card's INTERNAL AUTHENTICATE (the card pads). */
    fun digestInfo(data: ByteArray): ByteArray = when (this) {
        SHA256 -> DigestInfo.sha256(data)
        SHA1 -> SHA1_PREFIX + Sha.sha1(data)
    }

    companion object {
        // SEQUENCE { SEQUENCE { OID sha1, NULL }, OCTET STRING (20) }
        private val SHA1_PREFIX = "3021300906052B0E03021A05000414".decodeHex()

        /** "SHA-1" / "SHA1" / "sha-1" → SHA-1; anything else, including `null`, → SHA-256. */
        fun fromRequested(algorithm: String?): XadesDigest =
            if (algorithm?.replace("-", "")?.uppercase() == "SHA1") SHA1 else SHA256
    }
}

/**
 * XAdES-BES / T / C that matches what the MoldSign middleware (IAIK xades) writes: detached (`file:/<name>`) or
 * data-enveloping, with its quirks (docs/03). Port of the Swift `XAdESSigner`.
 *
 * - Every digested fragment is built already in canonical form: empty elements expanded, and the namespace
 *   declarations of the ancestors injected into the digested root, sorted by prefix (inclusive C14N of a subset).
 * - T adds a SignatureTimeStamp over the C14N SignatureValue; C adds CompleteCertificateRefs (signer + issuer CAs,
 *   not the self-signed root) and CompleteRevocationRefs: one CRL ref per certificate that publishes a CRL, and the
 *   vendor's duplicate OCSPRef (it queries the signer in every chain iteration, so one ref per certificate).
 * - A revocation or time-stamp service that fails fails the signature, so a "C" never lacks its references.
 */
class XadesDocumentSigner(
    private val trust: TrustServices,
    private val clock: Clock = Clock.systemDefaultZone(),
) : XadesSigner {
    override fun sign(
        documents: List<Document>,
        level: XadesLevel,
        packaging: XadesPackaging,
        certificateDer: ByteArray,
        chainDer: List<ByteArray>,
        signer: RawSigner,
        digest: XadesDigest,
    ): ByteArray {
        require(documents.isNotEmpty()) { "Nothing to sign" }
        val zone = clock.zone
        val u = UUID.randomUUID().toString().uppercase()
        val enveloping = packaging == XadesPackaging.Enveloping

        var references = ""
        var objectFormats = ""
        var fileObjects = ""
        documents.forEachIndexed { index, doc ->
            val base = attr(doc.name)
            val mime = if (doc.name.lowercase().endsWith(".txt")) "text/plain" else "application/octet-stream"
            val referenceId = "SignedFile-Reference-$u-$base"
            if (enveloping) {
                val objectId = "FileObject-$u" + if (index == 0) "" else "-$index"
                val xml = """<ds:Object Encoding="UTF-8" Id="$objectId">${b64(doc.bytes)}</ds:Object>"""
                fileObjects += xml
                val canonical = inject(xml, "ds:Object", listOf("ds" to NS_DS))
                references += """<ds:Reference Id="$referenceId" URI="#$objectId">${digestMethod(digest)}<ds:DigestValue>${b64(digest.hash(canonical))}</ds:DigestValue></ds:Reference>"""
            } else {
                references += """<ds:Reference Id="$referenceId" URI="file:/$base">${digestMethod(digest)}<ds:DigestValue>${b64(digest.hash(doc.bytes))}</ds:DigestValue></ds:Reference>"""
            }
            // vendor quirk: the ObjectReference carries the full path (here the document name), the Reference Id the basename
            objectFormats += """<xades:DataObjectFormat ObjectReference="$referenceId"><xades:Description>${text(doc.name)}</xades:Description><xades:MimeType>$mime</xades:MimeType></xades:DataObjectFormat>"""
        }

        val issuer = issuerOf(certificateDer)
        val signingTime = VendorNames.iso8601(clock.instant(), zone)
        val signedProps =
            """<xades:SignedProperties Id="SignedProperties-$u"><xades:SignedSignatureProperties><xades:SigningTime>$signingTime</xades:SigningTime>""" +
                """<xades:SigningCertificate><xades:Cert><xades:CertDigest>${digestMethod(digest)}<ds:DigestValue>${b64(digest.hash(certificateDer))}</ds:DigestValue></xades:CertDigest>""" +
                """<xades:IssuerSerial><ds:X509IssuerName>${text(issuer.name)}</ds:X509IssuerName><ds:X509SerialNumber>${issuer.serial}</ds:X509SerialNumber></xades:IssuerSerial></xades:Cert></xades:SigningCertificate></xades:SignedSignatureProperties>""" +
                """<xades:SignedDataObjectProperties Id="SignedDataObjectProperties-$u">$objectFormats</xades:SignedDataObjectProperties></xades:SignedProperties>"""
        val propsCanonical = inject(signedProps, "xades:SignedProperties", listOf("ds" to NS_DS, "xades" to NS_XADES))

        val signedInfoC14n = if (enveloping) "$ALG_C14N#WithComments" else ALG_C14N
        val signedInfo =
            """<ds:SignedInfo Id="SignedInfo-$u"><ds:CanonicalizationMethod Algorithm="$signedInfoC14n"></ds:CanonicalizationMethod>""" +
                """<ds:SignatureMethod Algorithm="${digest.signatureUri}"></ds:SignatureMethod>""" +
                """<ds:Reference Id="SignedProperties-Reference-$u" Type="http://uri.etsi.org/01903#SignedProperties" URI="#SignedProperties-$u">${digestMethod(digest)}<ds:DigestValue>${b64(digest.hash(propsCanonical))}</ds:DigestValue></ds:Reference>""" +
                "$references</ds:SignedInfo>"
        val signedInfoCanonical = inject(signedInfo, "ds:SignedInfo", listOf("ds" to NS_DS))
        val signatureValue = signer.sign(digest.digestInfo(signedInfoCanonical))
        val signatureValueXml = """<ds:SignatureValue Id="SignatureValue-$u">${b64(signatureValue)}</ds:SignatureValue>"""
        val keyInfo = """<ds:KeyInfo Id="KeyInfo-$u"><ds:X509Data><ds:X509Certificate>${b64(certificateDer)}</ds:X509Certificate></ds:X509Data></ds:KeyInfo>"""

        var unsigned = ""
        if (level != XadesLevel.BES) {
            val canonical = inject(signatureValueXml, "ds:SignatureValue", listOf("ds" to NS_DS))
            val token = trust.timestamp(Sha.sha256(canonical)) // the timestamp imprint stays SHA-256
            unsigned += """<xades:SignatureTimeStamp Id="SignatureTimeStamp-$u"><ds:CanonicalizationMethod Algorithm="$ALG_C14N"></ds:CanonicalizationMethod>""" +
                """<xades:EncapsulatedTimeStamp Encoding="http://uri.etsi.org/01903/v1.2.2#DER">${b64(token)}</xades:EncapsulatedTimeStamp></xades:SignatureTimeStamp>"""
        }
        if (level == XadesLevel.C) unsigned += completeRefs(u, certificateDer, chainDer, zone)
        if (unsigned.isNotEmpty()) {
            unsigned = "<xades:UnsignedProperties><xades:UnsignedSignatureProperties>$unsigned</xades:UnsignedSignatureProperties></xades:UnsignedProperties>"
        }

        val qualifying = """<ds:Object><xades:QualifyingProperties xmlns:xades="$NS_XADES" Target="#Signature-$u">$signedProps$unsigned</xades:QualifyingProperties></ds:Object>"""
        val signature = """<ds:Signature xmlns:ds="$NS_DS" Id="Signature-$u">$signedInfo$signatureValueXml$keyInfo$qualifying$fileObjects</ds:Signature>"""
        return ("""<?xml version="1.0" encoding="UTF-8" standalone="no"?>""" + signature).toByteArray(Charsets.UTF_8)
    }

    // ------------------------------------------------------------------ XAdES-C

    private fun completeRefs(u: String, signer: ByteArray, chain: List<ByteArray>, zone: ZoneId): String {
        val certificates = listOf(signer) + chain.filterNot { CertParts.parse(it).isSelfSigned }
        var certRefs = ""
        var crlRefs = ""
        var ocspRefs = ""
        // one OCSP answer about the signer, referenced once per certificate of the chain (vendor bug, docs/03)
        val ocsp = if (certificates.size > 1) trust.ocsp(certificates[0], certificates[1]) else null
        val ocspRef = ocsp?.let { response ->
            Revocation.ocspInfo(response, zone)?.let { info ->
                """<xades:OCSPRef><xades:OCSPIdentifier URI="$OCSP_URI"><xades:ResponderID><xades:ByName>${text(info.responder)}</xades:ByName></xades:ResponderID>""" +
                    """<xades:ProducedAt>${info.producedAt}</xades:ProducedAt></xades:OCSPIdentifier>""" +
                    """<xades:DigestAlgAndValue>${digestMethod(XadesDigest.SHA256)}<ds:DigestValue>${b64(Sha.sha256(response))}</ds:DigestValue></xades:DigestAlgAndValue></xades:OCSPRef>"""
            }
        }
        for (certificate in certificates) {
            val issuer = issuerOf(certificate)
            certRefs += """<xades:Cert><xades:CertDigest>${digestMethod(XadesDigest.SHA256)}<ds:DigestValue>${b64(Sha.sha256(certificate))}</ds:DigestValue></xades:CertDigest>""" +
                """<xades:IssuerSerial><ds:X509IssuerName>${text(issuer.namedName)}</ds:X509IssuerName><ds:X509SerialNumber>${issuer.serial}</ds:X509SerialNumber></xades:IssuerSerial></xades:Cert>"""
            Revocation.crlUrl(certificate)?.let { url ->
                val crl = trust.fetchCrl(url)
                val info = Revocation.crlInfo(crl, zone) ?: throw CardError.Format("Unreadable CRL from $url")
                crlRefs += """<xades:CRLRef><xades:DigestAlgAndValue>${digestMethod(XadesDigest.SHA256)}<ds:DigestValue>${b64(Sha.sha256(crl))}</ds:DigestValue></xades:DigestAlgAndValue>""" +
                    """<xades:CRLIdentifier URI="${attr(url)}"><xades:Issuer>${text(info.issuer)}</xades:Issuer><xades:IssueTime>${info.issueTime}</xades:IssueTime><xades:Number>${info.number}</xades:Number></xades:CRLIdentifier></xades:CRLRef>"""
            }
            if (ocspRef != null) ocspRefs += ocspRef
        }
        return """<xades:CompleteCertificateRefs Id="CompleteCertificateRefs-$u"><xades:CertRefs>$certRefs</xades:CertRefs></xades:CompleteCertificateRefs>""" +
            """<xades:CompleteRevocationRefs Id="CompleteRevocationRefs-$u"><xades:CRLRefs>$crlRefs</xades:CRLRefs><xades:OCSPRefs>$ocspRefs</xades:OCSPRefs></xades:CompleteRevocationRefs>"""
    }

    // ------------------------------------------------------------------ helpers

    private class IssuerSerial(val name: String, val namedName: String, val serial: String)

    private fun issuerOf(certificate: ByteArray): IssuerSerial {
        val parts = CertParts.parse(certificate)
        return IssuerSerial(
            name = VendorNames.rfc2253(parts.issuer, namedOrgId = false),
            namedName = VendorNames.rfc2253(parts.issuer, namedOrgId = true),
            serial = parts.serial.toString(),
        )
    }

    private fun digestMethod(digest: XadesDigest) = """<ds:DigestMethod Algorithm="${digest.digestUri}"></ds:DigestMethod>"""

    private fun b64(bytes: ByteArray) = Base64.getEncoder().encodeToString(bytes)

    /** Attribute value in the form C14N writes it back (`&`, `<`, `"`). */
    private fun attr(value: String) = value.replace("&", "&amp;").replace("<", "&lt;").replace("\"", "&quot;")

    /** Element text in the form C14N writes it back (`&`, `<`, `>`). */
    private fun text(value: String) = value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    /** Inserts the inherited namespace declarations (sorted by prefix) right after the root tag name. */
    private fun inject(xml: String, tag: String, namespaces: List<Pair<String, String>>): ByteArray {
        val declarations = namespaces.sortedBy { it.first }.joinToString("") { """ xmlns:${it.first}="${it.second}"""" }
        val at = xml.indexOf("<$tag") + tag.length + 1
        return (xml.substring(0, at) + declarations + xml.substring(at)).toByteArray(Charsets.UTF_8)
    }

    private companion object {
        const val NS_DS = "http://www.w3.org/2000/09/xmldsig#"
        const val NS_XADES = "http://uri.etsi.org/01903/v1.3.2#"
        const val ALG_C14N = "http://www.w3.org/TR/2001/REC-xml-c14n-20010315"
        const val OCSP_URI = "http://mdqsign.ocsp.pki.md"
    }
}
