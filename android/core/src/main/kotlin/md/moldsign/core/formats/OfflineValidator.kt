package md.moldsign.core

import java.io.ByteArrayInputStream
import java.security.GeneralSecurityException
import java.security.MessageDigest
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.util.Base64
import java.util.Date

/**
 * Offline validation of PAdES PDFs and XAdES documents produced by this app or the MoldSign middleware (docs/05).
 * No card, no network. Port of the Swift `Validator`, with DER read properly instead of scanned for byte patterns.
 *
 * What it checks, per signature: the signed content (PDF ByteRange, or the digests of the XAdES references), the RSA
 * signature over the signed attributes / SignedInfo, the issuer chain up to the embedded mdtrustca root (an offline
 * check: the leaf must be signed by the MDQSign CA and that by the root), and, when there is one, that the
 * time-stamp token covers the signature. It does not check revocation or the time-stamp token's own signature.
 *
 * Beyond the Swift validator: the PDF ByteRange must start at 0, enclose exactly one `/Contents <…>` string and
 * (for the last signature) reach the end of the file, so data appended after signing is reported as a change.
 */
class OfflineValidator(
    private val issuingCa: ByteArray = ChainCerts.mdQSign,
    private val rootCa: ByteArray = ChainCerts.mdTrustCA,
) : Validator {

    // ------------------------------------------------------------------ PAdES

    override fun verifyPdf(pdf: ByteArray): List<ValidationReport> {
        // Latin-1 keeps one char per byte, so the ByteRange offsets index the text directly.
        val text = String(pdf, Charsets.ISO_8859_1)
        val ranges = BYTE_RANGE.findAll(text).mapNotNull { match ->
            val n = match.groupValues.drop(1).map { it.toLongOrNull() ?: return@mapNotNull null }
            if (n.any { it > pdf.size }) null else n.map { it.toInt() }
        }.toList()
        val lastEnd = ranges.maxOfOrNull { it[2] + it[3] }
        return ranges.map { (a, b, c, d) -> pdfSignature(pdf, text, a, b, c, d, isLast = c + d == lastEnd) }
    }

    private fun pdfSignature(pdf: ByteArray, text: String, a: Int, b: Int, c: Int, d: Int, isLast: Boolean): ValidationReport {
        val details = ArrayList<String>()
        val gap = if (a + b < c && c <= pdf.size) text.substring(a + b, c) else ""
        val hex = gap.trim().takeIf { it.startsWith("<") && it.endsWith(">") }?.drop(1)?.dropLast(1)?.filterNot { it.isWhitespace() }
        val cms = hex?.takeIf { it.length % 2 == 0 && it.all { ch -> ch.isDigit() || ch in 'a'..'f' || ch in 'A'..'F' } }?.decodeHex()
        if (cms == null) return unreadable("PDF", "the ByteRange does not enclose a /Contents string")
        if (a != 0 || c + d > pdf.size) details += "ByteRange does not start at the beginning of the file"
        val covered = a == 0 && c + d <= pdf.size
        val reachesEnd = c + d == pdf.size
        if (isLast && covered && !reachesEnd) details += "${pdf.size - (c + d)} bytes after the signed range are not covered"
        val content = if (covered) pdf.copyOfRange(a, a + b) + pdf.copyOfRange(c, c + d) else ByteArray(0)
        val parts = try {
            Cms.parse(cms)
        } catch (e: CardError.Format) {
            return unreadable("PDF", e.message ?: "unreadable signature")
        }
        val intact = covered && (!isLast || reachesEnd) && MessageDigest.isEqual(parts.hash(content), parts.messageDigest)
        val signatureOk = parts.signer?.let { rsaVerify(it, parts.signedAttrsAsSet, parts.signature, parts.signatureAlgorithm) } ?: false
        if (parts.signer == null) details += "the signer certificate is not in the signature"
        val timestamp = parts.timestampToken?.let { timestamp(it, parts.signature, details) }
        return ValidationReport(
            certificateDetails = parts.signer?.let(::certificateDetails).orEmpty(),
            signerName = parts.signer?.let(::commonName),
            signingTime = parts.signingTime,
            timestampTime = timestamp,
            level = if (timestamp != null) "PAdES-B-T" else "PAdES-B-B",
            integrityOk = intact,
            signatureOk = signatureOk,
            chainOk = parts.signer?.let(::chainTrusted),
            details = details,
        )
    }

    // ------------------------------------------------------------------ XAdES

    override fun verifyXades(signatureXml: ByteArray, detachedDocuments: List<Document>): List<ValidationReport> {
        val doc = String(signatureXml, Charsets.UTF_8)
        val files = detachedDocuments.associate { it.name to it.bytes }
        val siStart = doc.indexOf("<ds:SignedInfo")
        val siEndTag = doc.indexOf("</ds:SignedInfo>")
        if (siStart < 0 || siEndTag < siStart) return emptyList()
        val signedInfo = doc.substring(siStart, siEndTag + "</ds:SignedInfo>".length)
        val details = ArrayList<String>()
        val missing = LinkedHashSet<String>()
        var referencesOk = true

        // SignedProperties, referenced as #SignedProperties-<id>
        val propsStart = doc.indexOf("<xades:SignedProperties")
        val propsEnd = doc.indexOf("</xades:SignedProperties>")
        val propsUri = referenceUris(signedInfo, "#SignedProperties-").firstOrNull()
        if (propsStart < 0 || propsEnd < propsStart || propsUri == null) {
            referencesOk = false
            details += "no SignedProperties reference"
        } else {
            val canonical = canonical(
                doc.substring(propsStart, propsEnd + "</xades:SignedProperties>".length), "xades:SignedProperties",
                listOf("ds" to NS_DS, "xades" to NS_XADES),
            )
            referencesOk = referencesOk && referenceMatches(signedInfo, propsUri, canonical)
        }
        // enveloping: the digest is over the C14N form of the embedded ds:Object
        for (uri in referenceUris(signedInfo, "#FileObject-")) {
            val start = doc.indexOf("""<ds:Object Encoding="UTF-8" Id="${uri.drop(1)}"""")
            val end = if (start >= 0) doc.indexOf("</ds:Object>", start) else -1
            if (end < 0) {
                referencesOk = false
                details += "embedded object $uri not found"
                continue
            }
            val canonical = canonical(doc.substring(start, end + "</ds:Object>".length), "ds:Object", listOf("ds" to NS_DS))
            referencesOk = referencesOk && referenceMatches(signedInfo, uri, canonical)
        }
        // detached: the digest is over the raw bytes of the named file
        for (uri in referenceUris(signedInfo, "file:/")) {
            val name = uri.removePrefix("file:/")
            val bytes = files[name]
            if (bytes == null) {
                missing += name
                referencesOk = false
            } else {
                referencesOk = referencesOk && referenceMatches(signedInfo, uri, bytes)
            }
        }

        val certificate = between(doc, "<ds:X509Certificate>", "</ds:X509Certificate>")?.let { base64(it) }
        val signatureValue = valueOf(doc, "ds:SignatureValue")?.let { base64(it) }
        val algorithm = if (signedInfo.contains("xmldsig#rsa-sha1\"")) "SHA1withRSA" else "SHA256withRSA"
        val signedInfoCanonical = canonical(signedInfo, "ds:SignedInfo", listOf("ds" to NS_DS))
        val signatureOk = certificate != null && signatureValue != null && rsaVerify(certificate, signedInfoCanonical, signatureValue, algorithm)
        if (certificate == null || signatureValue == null) details += "no certificate or no SignatureValue in the signature"

        val timestamp = between(doc, "<xades:EncapsulatedTimeStamp", "</xades:EncapsulatedTimeStamp>")
            ?.substringAfter('>')?.let { base64(it) }
            ?.let { token ->
                val svStart = doc.indexOf("<ds:SignatureValue")
                val svEnd = doc.indexOf("</ds:SignatureValue>")
                val signed = if (svStart >= 0 && svEnd > svStart) {
                    canonical(doc.substring(svStart, svEnd + "</ds:SignatureValue>".length), "ds:SignatureValue", listOf("ds" to NS_DS))
                } else {
                    ByteArray(0)
                }
                timestamp(token, signed, details)
            }
        val level = when {
            timestamp == null -> "XAdES-BES"
            doc.contains("CompleteCertificateRefs") -> "XAdES-C"
            else -> "XAdES-T"
        }
        return listOf(
            ValidationReport(
                certificateDetails = certificate?.let(::certificateDetails).orEmpty(),
                signerName = certificate?.let(::commonName),
                signingTime = between(doc, "<xades:SigningTime>", "</xades:SigningTime>")?.let(::isoDate),
                timestampTime = timestamp,
                level = level,
                integrityOk = referencesOk,
                signatureOk = signatureOk,
                chainOk = certificate?.let(::chainTrusted),
                details = details,
                missingDocuments = missing.toList(),
            ),
        )
    }

    // ------------------------------------------------------------------ XAdES string helpers

    /** `URI="<prefix>…"` values of the References in [signedInfo]. */
    private fun referenceUris(signedInfo: String, prefix: String): List<String> =
        Regex("""URI="(${Regex.escape(prefix)}[^"]*)"""").findAll(signedInfo).map { it.groupValues[1] }.toList()

    private fun referenceMatches(signedInfo: String, uri: String, data: ByteArray): Boolean {
        val at = signedInfo.indexOf("""URI="$uri"""")
        if (at < 0) return false
        val method = between(signedInfo.substring(at), "<ds:DigestMethod Algorithm=\"", "\"") ?: return false
        val expected = between(signedInfo.substring(at), "<ds:DigestValue>", "</ds:DigestValue>")?.let { base64(it) } ?: return false
        val digest = MessageDigest.getInstance(if (method.endsWith("#sha1")) "SHA-1" else "SHA-256").digest(data)
        return MessageDigest.isEqual(digest, expected)
    }

    private fun between(text: String, start: String, end: String): String? {
        val from = text.indexOf(start)
        if (from < 0) return null
        val to = text.indexOf(end, from + start.length)
        return if (to < 0) null else text.substring(from + start.length, to)
    }

    /** Text content of the first `<tag …>…</tag>`. */
    private fun valueOf(doc: String, tag: String): String? {
        val open = doc.indexOf("<$tag")
        if (open < 0) return null
        val gt = doc.indexOf('>', open)
        val close = doc.indexOf("</$tag>", gt)
        return if (gt < 0 || close < 0) null else doc.substring(gt + 1, close)
    }

    private fun base64(text: String): ByteArray? =
        try {
            Base64.getMimeDecoder().decode(text.filterNot { it.isWhitespace() })
        } catch (e: IllegalArgumentException) {
            null
        }

    private fun isoDate(text: String): Date? = try {
        Date.from(java.time.OffsetDateTime.parse(text.trim()).toInstant())
    } catch (e: java.time.format.DateTimeParseException) {
        null
    }

    /**
     * What C14N of a document subset gives for the fragments this app and the middleware write: the ancestors'
     * namespace declarations injected into the root (sorted by prefix) and empty elements expanded.
     */
    private fun canonical(fragment: String, rootTag: String, namespaces: List<Pair<String, String>>): ByteArray {
        val declarations = namespaces.sortedBy { it.first }.joinToString("") { """ xmlns:${it.first}="${it.second}"""" }
        val at = fragment.indexOf("<$rootTag").takeIf { it >= 0 }?.plus(rootTag.length + 1)
        val injected = if (at == null) fragment else fragment.substring(0, at) + declarations + fragment.substring(at)
        return expandEmptyElements(injected).toByteArray(Charsets.UTF_8)
    }

    /** `<e a="u/v"/>` → `<e a="u/v"></e>`, quote-aware. */
    private fun expandEmptyElements(xml: String): String {
        val out = StringBuilder(xml.length + 16)
        var i = 0
        while (i < xml.length) {
            val next = xml.getOrNull(i + 1)
            if (xml[i] == '<' && next != null && next != '/' && next != '?' && next != '!') {
                var j = i + 1
                while (j < xml.length && xml[j] != ' ' && xml[j] != '>' && xml[j] != '/') j++
                val tag = xml.substring(i + 1, j)
                var quoted = false
                while (j < xml.length) {
                    if (xml[j] == '"') quoted = !quoted
                    if (!quoted && xml[j] == '>') break
                    j++
                }
                if (j >= xml.length) {
                    out.append(xml, i, xml.length)
                    break
                }
                val element = xml.substring(i, j + 1)
                out.append(if (element.endsWith("/>")) element.dropLast(2) + "></$tag>" else element)
                i = j + 1
            } else {
                out.append(xml[i++])
            }
        }
        return out.toString()
    }

    // ------------------------------------------------------------------ certificates and signatures

    private fun x509(der: ByteArray): X509Certificate =
        CertificateFactory.getInstance("X.509").generateCertificate(ByteArrayInputStream(der)) as X509Certificate

    private fun certificateDetails(der: ByteArray): Map<String, String> = runCatching {
        val cert = x509(der)
        val dates = java.text.DateFormat.getDateTimeInstance(java.text.DateFormat.MEDIUM, java.text.DateFormat.SHORT)
        val fields = linkedMapOf(
            "Serial number" to cert.serialNumber.toString(16), "Valid from" to dates.format(cert.notBefore),
            "Valid until" to dates.format(cert.notAfter), "Public key" to (cert.publicKey.algorithm +
                ((cert.publicKey as? java.security.interfaces.RSAPublicKey)?.let { " ${it.modulus.bitLength()} bits" } ?: "")),
            "Certificate signature algorithm" to cert.sigAlgName,
            "SHA-256 fingerprint" to MessageDigest.getInstance("SHA-256").digest(der).joinToString("") { "%02x".format(it) },
            "Alternative names" to cert.subjectAlternativeNames.orEmpty().joinToString(),
            "Extended key usage" to cert.extendedKeyUsage.orEmpty().joinToString(),
            "Key usage" to cert.keyUsage?.toList()?.mapIndexedNotNull { i, enabled -> if (enabled) listOf("Digital signature", "Content commitment", "Key encipherment", "Data encipherment", "Key agreement", "Certificate signing", "CRL signing", "Encipher only", "Decipher only")[i] else null }.orEmpty().joinToString()
        )
        val labels = mapOf("2.5.4.3" to "Name", "2.5.4.5" to "Personal identifier", "2.5.4.6" to "Country",
            "2.5.4.7" to "City", "2.5.4.8" to "Region", "2.5.4.10" to "Organization", "2.5.4.11" to "Department",
            "2.5.4.20" to "Telephone", "2.5.4.97" to "Organization identifier")
        listOf("Subject" to cert.subjectX500Principal, "Issuer" to cert.issuerX500Principal).forEach { (group, principal) ->
            Der.read(principal.encoded).children().forEach { rdn ->
                rdn.children().forEach { attribute ->
                    val parts = attribute.children()
                    if (parts.size >= 2) {
                        val oid = VendorNames.dotted(parts[0].content)
                        val key = "$group · ${labels[oid] ?: oid}"
                        val charset = when (parts[1].tag) {
                            0x1E -> Charsets.UTF_16BE
                            0x1C -> java.nio.charset.Charset.forName("UTF-32BE")
                            0x14 -> Charsets.ISO_8859_1
                            else -> Charsets.UTF_8
                        }
                        val value = parts[1].content.toString(charset)
                        fields[key] = fields[key]?.let { "$it; $value" } ?: value
                    }
                }
            }
        }
        fields
    }.getOrDefault(emptyMap())

    private fun commonName(certificateDer: ByteArray): String? =
        try {
            CertificateSummary.parse(certificateDer).commonName
        } catch (e: GeneralSecurityException) {
            null
        }

    private fun rsaVerify(certificateDer: ByteArray, message: ByteArray, signature: ByteArray, algorithm: String): Boolean =
        try {
            Signature.getInstance(algorithm).run {
                initVerify(x509(certificateDer).publicKey)
                update(message)
                verify(signature)
            }
        } catch (e: GeneralSecurityException) {
            false
        } catch (e: RuntimeException) {
            false
        }

    /** Leaf issued by the MDQSign CA and that by the mdtrustca root, both signatures verified with the embedded keys. */
    private fun chainTrusted(leafDer: ByteArray): Boolean = try {
        val leaf = x509(leafDer)
        val ca = x509(issuingCa)
        val root = x509(rootCa)
        leaf.issuerX500Principal == ca.subjectX500Principal && ca.issuerX500Principal == root.subjectX500Principal &&
            runCatching { leaf.verify(ca.publicKey) }.isSuccess && runCatching { ca.verify(root.publicKey) }.isSuccess
    } catch (e: GeneralSecurityException) {
        false
    }

    /**
     * The generation time of an RFC 3161 [token] when its message imprint covers [signed] (the CMS signature value for
     * PAdES, the C14N SignatureValue element for XAdES); otherwise `null` with a note in [details].
     */
    private fun timestamp(token: ByteArray, signed: ByteArray, details: MutableList<String>): Date? {
        val info = try {
            Cms.timestampInfo(token)
        } catch (e: CardError.Format) {
            details += "unreadable time-stamp token"
            return null
        }
        // PAdES stamps the digest of the signature value; XAdES the digest of the canonical SignatureValue element
        val expected = MessageDigest.getInstance(info.hashAlgorithm).digest(signed)
        if (!MessageDigest.isEqual(expected, info.imprint)) {
            details += "the time-stamp does not cover this signature"
            return null
        }
        return info.genTime?.let(Date::from)
    }

    private fun unreadable(kind: String, why: String) = ValidationReport(
        signerName = null,
        signingTime = null,
        timestampTime = null,
        level = null,
        integrityOk = false,
        signatureOk = false,
        chainOk = null,
        details = listOf("$kind signature unreadable: $why"),
    )

    private companion object {
        const val NS_DS = "http://www.w3.org/2000/09/xmldsig#"
        const val NS_XADES = "http://uri.etsi.org/01903/v1.3.2#"
        val BYTE_RANGE = Regex("""/ByteRange\s*\[\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*\]""")
    }
}

/** The parts of a CMS SignedData (RFC 5652) a PAdES signature is checked with. */
internal class CmsParts(
    val signer: ByteArray?,
    val digestOid: String,
    val messageDigest: ByteArray,
    /** The `[0]` signedAttrs content: re-tagged as a SET it is what the signature covers. */
    private val signedAttrs: ByteArray,
    val signature: ByteArray,
    val signingTime: Date?,
    val timestampToken: ByteArray?,
) {
    val signedAttrsAsSet: ByteArray get() = Der.tlv(0x31, signedAttrs)

    val signatureAlgorithm: String
        get() = when (digestOid) {
            "1.3.14.3.2.26" -> "SHA1withRSA"
            "2.16.840.1.101.3.4.2.2" -> "SHA384withRSA"
            "2.16.840.1.101.3.4.2.3" -> "SHA512withRSA"
            else -> "SHA256withRSA"
        }

    fun hash(data: ByteArray): ByteArray = MessageDigest.getInstance(
        when (digestOid) {
            "1.3.14.3.2.26" -> "SHA-1"
            "2.16.840.1.101.3.4.2.2" -> "SHA-384"
            "2.16.840.1.101.3.4.2.3" -> "SHA-512"
            else -> "SHA-256"
        },
    ).digest(data)
}

internal class TimestampInfo(val hashAlgorithm: String, val imprint: ByteArray, val genTime: java.time.Instant?)

internal object Cms {
    private const val OID_MESSAGE_DIGEST = "1.2.840.113549.1.9.4"
    private const val OID_SIGNING_TIME = "1.2.840.113549.1.9.5"
    private const val OID_TIMESTAMP_TOKEN = "1.2.840.113549.1.9.16.2.14"

    fun parse(cms: ByteArray): CmsParts {
        val signedData = Der.read(cms).children().getOrNull(1)?.children()?.firstOrNull() ?: throw CardError.Format("Not a CMS SignedData")
        val parts = signedData.children()
        val certificates = parts.firstOrNull { it.tag == 0xA0 }?.children().orEmpty()
        val signerInfo = parts.lastOrNull { it.tag == 0x31 }?.children()?.firstOrNull()?.children()
            ?: throw CardError.Format("CMS without SignerInfo")
        var i = 1 // version
        val sid = signerInfo.getOrNull(i++) ?: throw CardError.Format("SignerInfo without sid")
        val digestOid = VendorNames.dotted(signerInfo.getOrNull(i++)?.children()?.firstOrNull()?.content ?: ByteArray(0))
        val attrs = signerInfo.getOrNull(i)?.takeIf { it.tag == 0xA0 }?.also { i++ } ?: throw CardError.Format("SignerInfo without signed attributes")
        i++ // signature algorithm
        val signature = signerInfo.getOrNull(i++)?.takeIf { it.tag == 0x04 }?.content ?: throw CardError.Format("SignerInfo without signature")
        val unsigned = signerInfo.getOrNull(i)?.takeIf { it.tag == 0xA1 }

        fun attribute(oid: String, from: Der.Node): Der.Node? = from.children()
            .firstOrNull { it.children().firstOrNull()?.let { o -> VendorNames.dotted(o.content) } == oid }
            ?.children()?.getOrNull(1)?.children()?.firstOrNull()
        val messageDigest = attribute(OID_MESSAGE_DIGEST, attrs)?.takeIf { it.tag == 0x04 }?.content
            ?: throw CardError.Format("No messageDigest attribute")
        return CmsParts(
            signer = signerCertificate(sid, certificates),
            digestOid = digestOid,
            messageDigest = messageDigest,
            signedAttrs = attrs.content,
            signature = signature,
            signingTime = attribute(OID_SIGNING_TIME, attrs)?.let(VendorNames::instant)?.let(Date::from),
            timestampToken = unsigned?.let { attribute(OID_TIMESTAMP_TOKEN, it) }?.encoded,
        )
    }

    /** The certificate whose issuer and serial are the SignerInfo's `IssuerAndSerialNumber`; the first one otherwise. */
    private fun signerCertificate(sid: Der.Node, certificates: List<Der.Node>): ByteArray? {
        val wanted = sid.children()
        val byId = if (sid.tag == 0x30 && wanted.size == 2) {
            certificates.firstOrNull {
                val c = CertParts.parse(it.encoded)
                c.issuer.contentEquals(wanted[0].encoded) && c.serialTlv.contentEquals(wanted[1].encoded)
            }
        } else {
            null
        }
        return (byId ?: certificates.firstOrNull())?.encoded
    }

    /** `TSTInfo` of a TimeStampToken: the imprint (hash algorithm + digest) and `genTime`. */
    fun timestampInfo(token: ByteArray): TimestampInfo {
        val signedData = Der.read(token).children().getOrNull(1)?.children()?.firstOrNull() ?: throw CardError.Format("Not a time-stamp token")
        val encapsulated = signedData.children().getOrNull(2)?.children()?.getOrNull(1)?.children()?.firstOrNull()
            ?: throw CardError.Format("Time-stamp token without TSTInfo")
        val info = Der.read(encapsulated.content).children() // version, policy, messageImprint, serialNumber, genTime, …
        val imprint = info.getOrNull(2)?.children() ?: throw CardError.Format("TSTInfo without messageImprint")
        val algorithm = when (VendorNames.dotted(imprint.getOrNull(0)?.children()?.firstOrNull()?.content ?: ByteArray(0))) {
            "1.3.14.3.2.26" -> "SHA-1"
            "2.16.840.1.101.3.4.2.2" -> "SHA-384"
            "2.16.840.1.101.3.4.2.3" -> "SHA-512"
            else -> "SHA-256"
        }
        return TimestampInfo(algorithm, imprint.getOrNull(1)?.content ?: ByteArray(0), info.getOrNull(4)?.let(VendorNames::instant))
    }
}
