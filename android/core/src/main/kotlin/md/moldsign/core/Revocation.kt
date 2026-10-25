package md.moldsign.core

import java.io.ByteArrayInputStream
import java.math.BigInteger
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.time.ZoneId

/**
 * OCSP request builder (RFC 6960) and the revocation metadata XAdES-C references (docs/03, docs/06). Port of the
 * Swift `TrustServices.ocspRequest`, `XAdESSigner.parseOCSPInfo` / `parseCRLInfo` / `extractExtensionURI`, but
 * reading the DER properly instead of scanning for byte patterns.
 */
internal object Revocation {
    private val SHA1_ALG_ID = Der.seq(Der.oid(byteArrayOf(0x2B, 0x0E, 0x03, 0x02, 0x1A)), Der.NULL)
    private const val OID_CRL_NUMBER = "2.5.29.20"
    private const val OID_CRL_DISTRIBUTION_POINTS = "2.5.29.31"

    /** OCSPRequest for one certificate: SHA-1 CertID (what `openssl ocsp` sends), no nonce. */
    fun ocspRequest(certificateDer: ByteArray, issuerDer: ByteArray): ByteArray {
        val leaf = CertParts.parse(certificateDer)
        val issuer = CertParts.parse(issuerDer)
        val certId = Der.seq(
            SHA1_ALG_ID,
            Der.octetString(Sha.sha1(issuer.subject)),
            Der.octetString(Sha.sha1(issuer.publicKeyBits)),
            leaf.serialTlv,
        )
        // Request, requestList, TBSRequest, OCSPRequest: one SEQUENCE each
        return Der.seq(Der.seq(Der.seq(Der.seq(certId))))
    }

    class OcspInfo(val responder: String, val producedAt: String)

    /**
     * ResponderID (by name, reversed RFC 2253 with the named organizationIdentifier) and `producedAt` of an
     * OCSPResponse, or `null` when it is not a successful response with a BasicOCSPResponse.
     */
    fun ocspInfo(response: ByteArray, zone: ZoneId): OcspInfo? = try {
        val top = Der.read(response).children()
        val bytes = top.getOrNull(1)?.takeIf { it.tag == 0xA0 }?.children()?.firstOrNull() // ResponseBytes
        val basic = bytes?.children()?.getOrNull(1)?.let { Der.read(it.content) } // BasicOCSPResponse
        val tbs = basic?.children()?.firstOrNull()?.children() // ResponseData
        if (tbs == null) {
            null
        } else {
            var i = if (tbs.firstOrNull()?.tag == 0xA0) 1 else 0 // [0] version
            val responderId = tbs.getOrNull(i++)
            val produced = tbs.getOrNull(i)
            val name = responderId?.takeIf { it.tag == 0xA1 }?.children()?.firstOrNull()
            OcspInfo(
                responder = name?.let { VendorNames.rfc2253(it.encoded, namedOrgId = true) }.orEmpty(),
                producedAt = VendorNames.time(produced, zone),
            )
        }
    } catch (e: CardError.Format) {
        null
    }

    class CrlInfo(val issuer: String, val issueTime: String, val number: String)

    /** Issuer, `thisUpdate` and CRL number of a CertificateList. */
    fun crlInfo(crl: ByteArray, zone: ZoneId): CrlInfo? = try {
        val tbs = Der.read(crl).children().firstOrNull()?.children().orEmpty()
        var i = if (tbs.firstOrNull()?.tag == 0x02) 1 else 0 // version
        i++ // signature algorithm
        val issuer = tbs.getOrNull(i++)
        val thisUpdate = tbs.getOrNull(i)
        if (issuer == null || thisUpdate == null) {
            null
        } else {
            CrlInfo(
                issuer = VendorNames.rfc2253(issuer.encoded, namedOrgId = true),
                issueTime = VendorNames.time(thisUpdate, zone),
                number = crlNumber(tbs)?.toString() ?: "0",
            )
        }
    } catch (e: CardError.Format) {
        null
    }

    private fun crlNumber(tbs: List<Der.Node>): BigInteger? {
        val extensions = tbs.firstOrNull { it.tag == 0xA0 }?.children()?.firstOrNull()?.children() ?: return null
        for (ext in extensions) {
            val parts = ext.children()
            if (parts.size < 2 || VendorNames.dotted(parts[0].content) != OID_CRL_NUMBER) continue
            val value = Der.read(parts.last().content)
            if (value.tag == 0x02) return BigInteger(1, value.content)
        }
        return null
    }

    /** First `http` URI of the certificate's CRL Distribution Points, or `null`. */
    fun crlUrl(certificateDer: ByteArray): String? {
        val cert = CertificateFactory.getInstance("X.509").generateCertificate(ByteArrayInputStream(certificateDer)) as X509Certificate
        val wrapped = cert.getExtensionValue(OID_CRL_DISTRIBUTION_POINTS) ?: return null
        return try {
            firstUri(Der.read(Der.read(wrapped).content))
        } catch (e: CardError.Format) {
            null
        }
    }

    // GeneralName uniformResourceIdentifier is [6] IMPLICIT IA5String: tag 0x86
    private fun firstUri(node: Der.Node): String? {
        if (node.tag == 0x86) return String(node.content, Charsets.US_ASCII).takeIf { it.startsWith("http", ignoreCase = true) }
        if (node.tag and 0x20 == 0) return null
        for (child in node.children()) firstUri(child)?.let { return it }
        return null
    }
}
