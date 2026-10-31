package md.moldsign.core

import java.math.BigInteger
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/** The fields of an X.509 certificate that the OCSP CertID and the XAdES references need, straight from the DER. */
internal class CertParts private constructor(
    /** The serial as the full INTEGER TLV (the OCSP CertID embeds it untouched). */
    val serialTlv: ByteArray,
    val serial: BigInteger,
    val issuer: ByteArray,
    val subject: ByteArray,
    /** subjectPublicKey BIT STRING content without the unused-bits byte (what the CertID hashes). */
    val publicKeyBits: ByteArray,
) {
    val isSelfSigned: Boolean get() = issuer.contentEquals(subject)

    companion object {
        fun parse(certificate: ByteArray): CertParts {
            val tbs = Der.read(certificate).children().firstOrNull() ?: throw CardError.Format("Not a certificate")
            val fields = tbs.children()
            var i = if (fields.firstOrNull()?.tag == 0xA0) 1 else 0 // [0] version
            val serial = fields.getOrNull(i++) ?: throw CardError.Format("Certificate without serial number")
            i++ // signature algorithm
            val issuer = fields.getOrNull(i++) ?: throw CardError.Format("Certificate without issuer")
            i++ // validity
            val subject = fields.getOrNull(i++) ?: throw CardError.Format("Certificate without subject")
            val spki = fields.getOrNull(i)?.children() ?: throw CardError.Format("Certificate without public key")
            val bits = spki.getOrNull(1)?.takeIf { it.tag == 0x03 && it.length > 1 }
                ?: throw CardError.Format("Certificate public key is not a BIT STRING")
            return CertParts(
                serialTlv = serial.encoded,
                serial = BigInteger(1, serial.content),
                issuer = issuer.encoded,
                subject = subject.encoded,
                publicKeyBits = bits.content.copyOfRange(1, bits.length),
            )
        }
    }
}

/**
 * Vendor-faithful Name rendering and ASN.1 time conversion (Swift `XAdESSigner.rfc2253Name`, `parseASN1Time`).
 *
 * The XAdES `X509IssuerName` must match the MoldSign middleware byte for byte: RFC 2253 order (DER reversed), UTF-8
 * bytes from 0x7F up escaped as `\XX` ("\C8\9B"), unknown attributes as dotted OIDs. For display use the decoded
 * names of [CertificateSummary] instead.
 */
internal object VendorNames {
    private val SHORT = mapOf(
        "2.5.4.6" to "C", "2.5.4.8" to "ST", "2.5.4.7" to "L", "2.5.4.10" to "O", "2.5.4.3" to "CN",
        "2.5.4.5" to "serialNumber", "2.5.4.97" to "organizationIdentifier", "2.5.4.20" to "T",
    )

    /**
     * [namedOrgId]: `organizationIdentifier=` (CompleteCertificateRefs, OCSP responder, CRL issuer) instead of the
     * numeric `2.5.4.97=` the SigningCertificate carries.
     */
    fun rfc2253(name: ByteArray, namedOrgId: Boolean, reverse: Boolean = true): String {
        val sets = Der.read(name).children().let { if (reverse) it.reversed() else it }
        val out = ArrayList<String>()
        for (set in sets) {
            for (ava in set.children()) {
                val parts = ava.children()
                if (parts.size < 2) continue
                val oid = dotted(parts[0].content)
                val short = SHORT[oid] ?: oid
                val type = if (namedOrgId || short != "organizationIdentifier") short else oid
                val value = StringBuilder()
                for (b in parts[1].content) {
                    val v = b.toInt() and 0xFF
                    if (v >= 0x7F || v == 0) value.append("\\%02X".format(v)) else value.append(v.toChar())
                }
                out += "$type=$value"
            }
        }
        return out.joinToString(",")
    }

    fun dotted(oid: ByteArray): String {
        if (oid.isEmpty()) return ""
        val first = oid[0].toInt() and 0xFF
        val parts = arrayListOf((first / 40).toString(), (first % 40).toString())
        var acc = 0L
        for (i in 1 until oid.size) {
            val b = oid[i].toInt() and 0xFF
            acc = (acc shl 7) or (b and 0x7F).toLong()
            if (b and 0x80 == 0) {
                parts += acc.toString()
                acc = 0
            }
        }
        return parts.joinToString(".")
    }

    private val ISO = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssxxx", Locale.ROOT)

    /** `2026-10-25T21:58:25+02:00`: the format of SigningTime, ProducedAt and the CRL IssueTime. */
    fun iso8601(instant: Instant, zone: ZoneId): String = ISO.format(ZonedDateTime.ofInstant(instant, zone))

    /** UTCTime (0x17) or GeneralizedTime (0x18) node → ISO 8601 in [zone]; the raw text when it is not a known form. */
    fun time(node: Der.Node?, zone: ZoneId): String {
        node ?: return ""
        return instant(node)?.let { iso8601(it, zone) } ?: String(node.content, Charsets.US_ASCII)
    }

    /** UTCTime (years 50–99 → 19xx, RFC 5280) or GeneralizedTime in UTC; fractions of a second are dropped. `null` when unreadable. */
    fun instant(node: Der.Node?): Instant? {
        node ?: return null
        if (node.tag != 0x17 && node.tag != 0x18) return null
        val digits = String(node.content, Charsets.US_ASCII).removeSuffix("Z").substringBefore('.')
        if (!digits.all { it.isDigit() }) return null
        return try {
            val (year, rest) = when (node.tag) {
                0x17 -> (digits.substring(0, 2).toInt().let { if (it >= 50) 1900 + it else 2000 + it }) to digits.substring(2)
                else -> digits.substring(0, 4).toInt() to digits.substring(4)
            }
            ZonedDateTime.of(
                year, rest.substring(0, 2).toInt(), rest.substring(2, 4).toInt(),
                rest.substring(4, 6).toInt(), rest.substring(6, 8).toInt(), rest.substring(8, 10).toInt(), 0, ZoneOffset.UTC,
            ).toInstant()
        } catch (e: RuntimeException) {
            null
        }
    }
}
