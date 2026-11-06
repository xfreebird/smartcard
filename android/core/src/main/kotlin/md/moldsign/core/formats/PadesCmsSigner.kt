package md.moldsign.core

import java.nio.charset.StandardCharsets.ISO_8859_1
import java.time.Clock
import java.time.ZoneOffset
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

/**
 * PAdES-T as the MoldSign / iText app writes it (docs/02), ported from Swift `PAdESSigner`: an incremental update
 * appended after the last `%%EOF` (signature dictionary with a fixed-width `/Contents` placeholder, AcroForm, field
 * and widget, the original catalog updated), then a detached CAdES CMS with the signing-certificate-v2 attribute,
 * the CA chain and an RFC 3161 token as unsigned attribute.
 *
 * The PDF is scanned as ISO-8859-1 text so one character is one byte and offsets stay exact.
 */
class PadesCmsSigner(
    private val trust: TrustServices,
    private val clock: Clock = Clock.systemDefaultZone(),
) : PadesSigner {

    override fun sign(pdf: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner): ByteArray = signPdf(pdf, certificateDer, chainDer, signer, null)

    override fun signVisible(pdf: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner, placement: PdfStampPlacement): ByteArray = signPdf(pdf, certificateDer, chainDer, signer, placement)

    private fun signPdf(pdf: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner, placement: PdfStampPlacement?): ByteArray {
        if (placement?.documentSHA256 != null && !placement.documentSHA256.equals(Sha.sha256(pdf).toHex(), ignoreCase = true))
            throw CardError.Format("The PDF changed after stamp placement. Open the preview again")
        val signingDate = ZonedDateTime.now(clock)
        val text = String(pdf, ISO_8859_1)

        // --- trailer info ---
        val eof = text.lastIndexOf("%%EOF")
        val startxref = text.lastIndexOf("startxref")
        if (eof < 0 || startxref < 0 || startxref > eof) throw CardError.Format("Cannot find the PDF trailer")
        val previousXref = text.substring(startxref + "startxref".length, eof).trim().toIntOrNull()
            ?: throw CardError.Format("Bad startxref")
        val trailerTail = text.takeLast(2048)
        val rootNum = Regex("""/Root (\d+) 0 R""").find(trailerTail)?.groupValues?.get(1)?.toIntOrNull()
            ?: throw CardError.Format("No /Root in the PDF trailer")
        val id = Regex("""/ID\s*\[\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>""").find(trailerTail)?.groupValues

        // --- original catalog (plain-text search of its latest version) ---
        val catalog = findObjectDict(text, rootNum) ?: throw CardError.Format("PDF catalog object not found")
        // counter-signing: reuse the existing AcroForm and append our field to /Fields
        val existingAcro = Regex("""/AcroForm (\d+) 0 R""").find(catalog)?.groupValues?.get(1)?.toIntOrNull()

        // anchored with (?<!\d): a bare (\d+) is quadratic over the 37,960-zero /Contents of an earlier signature
        val scannedMax = Regex("""(?<!\d)(\d+) 0 obj""").findAll(text).maxOfOrNull { it.groupValues[1].toIntOrNull() ?: 0 } ?: 0
        val declaredMax = Regex("""/Size\s+(\d+)\b""").findAll(text).maxOfOrNull { it.groupValues[1].toIntOrNull() ?: 1 } ?: 1
        val maxObj = maxOf(scannedMax, declaredMax - 1)
        val sigNum = maxObj + 1
        val acroNum = maxObj + 2
        val fieldNum = maxObj + 3
        val pageNum = findFirstPage(text)

        // --- appended objects (ByteRange and Contents use fixed-width placeholders) ---
        val byteRangeDummy = "/ByteRange [0 0000000000 0000000000 0000000000 ]"
        val contents = "/Contents<" + "0".repeat(PLACEHOLDER_HEX_LENGTH) + ">"
        val sigDict = "\n$sigNum 0 obj\n<</Type/Sig /Filter/Adobe.PPKLite /SubFilter/ETSI.CAdES.detached $byteRangeDummy " +
            "$contents /M(${signingDate.format(PDF_DATE).replace(":00", "'00'")}) /Reason(MoldSign Signature) /Location(Moldova) /ContactInfo() " +
            "/Prop_Build<</App<</Name/>>>>>>\nendobj\n"
        val pageRef = pageNum?.let { "/P $it 0 R" } ?: ""
        // next free field name: highest existing "/T (SignatureN)" + 1 (iText writes a space after /T)
        val lastSignature = Regex("""/T\s*\(\s*Signature(\d+)""").findAll(text).maxOfOrNull { it.groupValues[1].toIntOrNull() ?: 0 } ?: 0
        val sigField = "$fieldNum 0 obj\n<</FT/Sig /T(Signature${lastSignature + 1}) /Type/Annot /Subtype/Widget " +
            "/Rect[0 0 0 0] /F 0 $pageRef /V $sigNum 0 R>>\nendobj\n"

        var chunks: List<String>
        val acroDict = existingAcro?.let { findObjectDict(text, it) }
        if (existingAcro != null && acroDict != null) {
            val fields = Regex("""/Fields\s*\[([^\]]*)\]""").find(acroDict) ?: throw CardError.Format("AcroForm /Fields not found")
            var newAcro = acroDict.replaceRange(fields.range, "/Fields[${fields.groupValues[1].trim()} $fieldNum 0 R]")
            if (!newAcro.contains("/SigFlags")) newAcro = dictInserting(newAcro, "/SigFlags 3")
            chunks = listOf(sigDict, sigField, "$existingAcro 0 obj\n$newAcro\nendobj\n")
        } else {
            val acroForm = "$acroNum 0 obj\n<</Fields[$fieldNum 0 R]/SigFlags 3>>\nendobj\n"
            val extensions = "/Extensions<</ESIC<</BaseVersion/1.7/ExtensionLevel 2>>>>"
            val catalogUpdated = "$rootNum 0 obj\n${dictInserting(catalog, "/AcroForm $acroNum 0 R $extensions")}\nendobj\n"
            chunks = listOf(sigDict, acroForm, sigField, catalogUpdated)
        }

        var nextObject = maxObj + 4
        if (placement != null) {
            val visible = StampPdf.appearance(text, catalog, fieldNum, sigNum, nextObject, "Signature${lastSignature + 1}",
                placement, CertificateSummary.parse(certificateDer).commonName, signingDate)
            chunks = chunks.map { if (it == sigField) visible.field else it } + visible.chunks
            nextObject = visible.next
        }

        // --- xref (one subsection per object, iText style); offsets are absolute in the final file ---
        val appendOffset = pdf.size
        var position = appendOffset
        val offsets = ArrayList<Pair<Int, Int>>()
        for (chunk in chunks) {
            val num = chunk.dropWhile { !it.isDigit() }.takeWhile { it.isDigit() }.toInt()
            offsets += num to (position + if (chunk.startsWith("\n")) 1 else 0)
            position += chunk.length
        }
        val body = chunks.joinToString("")
        val xrefPosition = appendOffset + body.length
        val xref = StringBuilder("xref\n0 1\n0000000000 65535 f \n")
        for ((num, offset) in offsets.sortedBy { it.first }) xref.append("$num 1\n${pad10(offset)} 00000 n \n")
        val trailer = StringBuilder("trailer\n<</Size ${nextObject} /Root $rootNum 0 R /Prev $previousXref")
        if (id != null) trailer.append(" /ID [<${id[1]}><${id[2]}>]")
        trailer.append(">>\nstartxref\n$xrefPosition\n%%EOF\n")

        var appended = body + xref + trailer
        val total = appendOffset + appended.length

        // --- ByteRange around the /Contents hex (the angle brackets are excluded too) ---
        val marker = "/Contents<"
        val markerAt = appended.lastIndexOf(marker)
        if (markerAt < 0) throw CardError.Format("Signature placeholder not found")
        val hexStart = appendOffset + markerAt + marker.length // first hex character
        val hexEnd = hexStart + PLACEHOLDER_HEX_LENGTH // byte after the last hex character
        val byteRange = "/ByteRange [0 ${pad10(hexStart - 1)} ${pad10(hexEnd + 1)} ${pad10(total - hexEnd - 1)} ]"
        appended = appended.replaceFirst(byteRangeDummy, byteRange)
        check(appendOffset + appended.length == total) { "ByteRange patch changed the update size" }

        val signed = pdf + appended.toByteArray(ISO_8859_1)
        val contentDigest = Sha.sha256(signed.copyOfRange(0, hexStart - 1), signed.copyOfRange(hexEnd + 1, total))

        // --- CMS, then hex into the placeholder ---
        val cms = buildCms(contentDigest, certificateDer, chainDer, signer, signingDate)
        val cmsHex = cms.toHex().lowercase()
        if (cmsHex.length > PLACEHOLDER_HEX_LENGTH) throw CardError.Format("CMS does not fit the signature placeholder")
        System.arraycopy(cmsHex.toByteArray(ISO_8859_1), 0, signed, hexStart, cmsHex.length)
        return signed
    }

    /** CAdES CMS: signed attributes, the card's RSA signature over them, the chain and the RFC 3161 token. */
    internal fun buildCms(contentDigest: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner, signingDate: ZonedDateTime = ZonedDateTime.now(clock)): ByteArray {
        val (issuer, serial) = issuerAndSerial(certificateDer)
        val signedAttributes = Der.concat(
            Der.seq(Der.oid(OID_CONTENT_TYPE), Der.set(Der.oid(OID_ID_DATA))),
            Der.seq(Der.oid(OID_SIGNING_TIME), Der.set(Der.tlv(0x17, UTC_TIME.format(signingDate).toByteArray(ISO_8859_1)))),
            Der.seq(Der.oid(OID_MESSAGE_DIGEST), Der.set(Der.octetString(contentDigest))),
            // signingCertificateV2: SET { SEQ { SEQ { SEQ { OCTET STRING sha256(cert) } } } }
            Der.seq(Der.oid(OID_SIGNING_CERTIFICATE_V2), Der.set(Der.seq(Der.seq(Der.seq(Der.octetString(Sha.sha256(certificateDer))))))),
        )
        // the signature covers the attributes as a SET, not with the [0] tag they carry inside SignerInfo
        val digestInfo = DigestInfo.forSha256Digest(Sha.sha256(Der.set(signedAttributes)))
        val signature = signer.sign(digestInfo)
        if (signature.isEmpty()) throw CardError.Format("The card returned an empty signature")

        val token = trust.timestamp(Sha.sha256(signature))
        val unsignedAttributes = Der.seq(Der.oid(OID_TIMESTAMP_TOKEN), Der.set(token))

        val sha256Algorithm = Der.seq(Der.oid(OID_SHA256), Der.NULL)
        val signerInfo = Der.seq(
            Der.integer(1),
            Der.seq(issuer, serial),
            sha256Algorithm,
            Der.tlv(0xA0, signedAttributes),
            Der.seq(Der.oid(OID_SHA256_WITH_RSA), Der.NULL),
            Der.octetString(signature),
            Der.tlv(0xA1, unsignedAttributes),
        )
        val signedData = Der.seq(
            Der.integer(1),
            Der.set(sha256Algorithm),
            Der.seq(Der.oid(OID_ID_DATA)),
            Der.tlv(0xA0, Der.concat(certificateDer, *chainDer.toTypedArray())),
            Der.set(signerInfo),
        )
        return Der.seq(Der.oid(OID_ID_SIGNED_DATA), Der.tlv(0xA0, signedData))
    }

    /** Raw TLVs of the issuer Name and the serial INTEGER, copied from the certificate as is. */
    private fun issuerAndSerial(certificateDer: ByteArray): Pair<ByteArray, ByteArray> {
        val tbs = Der.read(certificateDer).children().firstOrNull() ?: throw CardError.Format("Not an X.509 certificate")
        val fields = tbs.children()
        val first = if (fields.firstOrNull()?.tag == 0xA0) 1 else 0 // optional [0] version
        if (fields.size < first + 3) throw CardError.Format("Not an X.509 certificate")
        return fields[first + 2].encoded to fields[first].encoded // issuer, serial (signature algorithm sits between)
    }

    private fun utcTime(): String = UTC_TIME.format(clock.instant())

    /** `D:yyyyMMddHHmmss+03'00'` (the colon of the offset becomes `'00'`). */
    private fun pdfDate(): String = ZonedDateTime.now(clock).format(PDF_DATE).replace(":00", "'00'")

    private fun pad10(value: Int) = value.toString().padStart(10, '0')

    /** Inserts [entries] before the final `>>` of a `<< ... >>` dictionary. */
    private fun dictInserting(dict: String, entries: String): String {
        val at = dict.lastIndexOf(">>")
        return if (at < 0) dict else dict.substring(0, at) + entries + dict.substring(at)
    }

    /** The `<< ... >>` dictionary of the LATEST version of object [num] (plain-text objects only). */
    private fun findObjectDict(text: String, num: Int): String? {
        val last = Regex("""(?<!\d)$num 0 obj""").findAll(text).lastOrNull() ?: return null
        val start = text.indexOf("<<", last.range.last + 1)
        if (start < 0) return null
        var depth = 0
        var i = start
        while (i < text.length) {
            when {
                text.startsWith("<<", i) -> { depth++; i += 2 }
                text.startsWith(">>", i) -> {
                    depth--
                    i += 2
                    if (depth == 0) return text.substring(start, i)
                }
                else -> i++
            }
        }
        return null
    }

    /** First `/Type/Page` object (not `/Pages`), for the widget's optional `/P`. */
    private fun findFirstPage(text: String): Int? {
        for (m in Regex("""(?<!\d)(\d+) 0 obj""").findAll(text)) {
            val slice = text.substring(m.range.last + 1, minOf(text.length, m.range.last + 301))
            if (slice.contains("/Type/Page") && !slice.contains("/Type/Pages")) return m.groupValues[1].toIntOrNull()
        }
        return null
    }

    private companion object {
        /** Same reserve as the MoldSign Java app: the offsets never move, whatever the CMS size. */
        const val PLACEHOLDER_HEX_LENGTH = 37960

        val UTC_TIME: DateTimeFormatter = DateTimeFormatter.ofPattern("yyMMddHHmmss'Z'").withZone(ZoneOffset.UTC)
        val PDF_DATE: DateTimeFormatter = DateTimeFormatter.ofPattern("'D:'yyyyMMddHHmmssXXX")

        val OID_SHA256 = byteArrayOf(0x60, 0x86.toByte(), 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01)
        val OID_SHA256_WITH_RSA = pkcs(1, 1, 11)
        val OID_ID_DATA = pkcs(1, 7, 1)
        val OID_ID_SIGNED_DATA = pkcs(1, 7, 2)
        val OID_CONTENT_TYPE = pkcs(1, 9, 3)
        val OID_SIGNING_TIME = pkcs(1, 9, 5)
        val OID_MESSAGE_DIGEST = pkcs(1, 9, 4)
        val OID_SIGNING_CERTIFICATE_V2 = pkcs(1, 9, 16, 2, 47)
        val OID_TIMESTAMP_TOKEN = pkcs(1, 9, 16, 2, 14)

        /** DER content of 1.2.840.113549.<arcs> (all arcs used here are below 128). */
        fun pkcs(vararg arcs: Int): ByteArray =
            byteArrayOf(0x2A, 0x86.toByte(), 0x48, 0x86.toByte(), 0xF7.toByte(), 0x0D) + ByteArray(arcs.size) { arcs[it].toByte() }
    }
}
