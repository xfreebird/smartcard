package md.moldsign.core

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * MDQTSA / CRL / OCSP over plain HTTP with `HttpURLConnection` (docs/06). The PKI endpoints are HTTP-only and their
 * payloads are signed; the app's network security config allows cleartext for exactly these hosts.
 */
class MdTrustServices(
    private val timeoutMs: Int = 30_000,
    private val tsaUrl: String = TSA_URL,
    private val ocspUrl: String = OCSP_URL,
    private val retryDelayMs: Long = 1_000,
) : TrustServices {

    override fun timestamp(messageImprint: ByteArray): ByteArray {
        val response = try {
            http("POST", tsaUrl, TimestampRequest.build(messageImprint), "application/timestamp-query")
        } catch (e: IOException) {
            throw CardError.Network("MDQTSA", e)
        }
        return TimestampRequest.token(response)
    }

    override fun fetchCrl(url: String): ByteArray = try {
        http("GET", url, null, null)
    } catch (e: IOException) {
        throw CardError.Network("CRL", e)
    }

    /** The responder's raw OCSPResponse for [certificateDer] (SHA-1 CertID, no nonce, like `openssl ocsp`). */
    override fun ocsp(certificateDer: ByteArray, issuerDer: ByteArray): ByteArray {
        val response = try {
            http("POST", ocspUrl, Revocation.ocspRequest(certificateDer, issuerDer), "application/ocsp-request")
        } catch (e: IOException) {
            throw CardError.Network("OCSP", e)
        }
        // An error status ("malformedRequest", "tryLater", …) is a 5-byte body: no BasicOCSPResponse to reference.
        if (response.size <= MIN_OCSP_RESPONSE) throw CardError.Network("OCSP (no usable response)")
        return response
    }

    /**
     * One request with a single retry: the PKI gateways answer the first request after an idle spell with
     * 502/503/504 (seen on the OCSP responder: a 13 s 502, then ~20 ms), or drop the connection.
     */
    private fun http(method: String, url: String, body: ByteArray?, contentType: String?): ByteArray {
        try {
            return httpOnce(method, url, body, contentType)
        } catch (e: IOException) {
            val transient = e !is HttpStatusException || e.status in TRANSIENT_STATUSES
            if (!transient) throw e
            Thread.sleep(retryDelayMs)
            return httpOnce(method, url, body, contentType)
        }
    }

    private class HttpStatusException(val status: Int, url: String) : IOException("HTTP $status from $url")

    private fun httpOnce(method: String, url: String, body: ByteArray?, contentType: String?): ByteArray {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = method
            connection.connectTimeout = timeoutMs
            connection.readTimeout = timeoutMs
            // the TSA answers 301 to a path without its trailing slash: callers pass the exact URL, never follow
            connection.instanceFollowRedirects = false
            connection.setRequestProperty("Accept", "*/*")
            contentType?.let { connection.setRequestProperty("Content-Type", it) }
            if (body != null) {
                connection.doOutput = true
                connection.setFixedLengthStreamingMode(body.size)
                connection.outputStream.use { it.write(body) }
            }
            val status = connection.responseCode
            if (status != HttpURLConnection.HTTP_OK) throw HttpStatusException(status, url)
            return connection.inputStream.use { it.readBytes() }
        } finally {
            connection.disconnect()
        }
    }

    companion object {
        const val TSA_URL = "http://tsp.pki.gov.md/moldsign2/"
        const val OCSP_URL = "http://mdqsign.ocsp.pki.md"
        private const val MIN_OCSP_RESPONSE = 100
        private val TRANSIENT_STATUSES = setOf(502, 503, 504)
    }
}

/** RFC 3161 TimeStampReq builder and TimeStampResp reader (Swift `TimestampRequest.swift` + `fetchTimestampToken`). */
internal object TimestampRequest {
    private val OID_SHA256 = byteArrayOf(0x60, 0x86.toByte(), 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01)

    /** TimeStampReq { version 1, messageImprint { sha256, digest }, certReq TRUE }. */
    fun build(sha256: ByteArray): ByteArray {
        require(sha256.size == 32) { "SHA-256 digest must be 32 bytes, got ${sha256.size}" }
        val imprint = Der.seq(Der.seq(Der.oid(OID_SHA256), Der.NULL), Der.octetString(sha256))
        return Der.seq(Der.integer(1), imprint, byteArrayOf(0x01, 0x01, 0xFF.toByte()))
    }

    /** The TimeStampToken (ContentInfo) of a TimeStampResp, whose PKIStatus must be granted (0) or grantedWithMods (1). */
    fun token(response: ByteArray): ByteArray {
        val parts = try {
            Der.read(response).children()
        } catch (e: CardError.Format) {
            throw CardError.Network("MDQTSA", e)
        }
        val status = parts.firstOrNull()?.children()?.firstOrNull()?.content?.lastOrNull()?.toInt()
        if (status == null || status > 1) throw CardError.Network("MDQTSA (status ${status ?: "missing"})")
        if (parts.size < 2) throw CardError.Network("MDQTSA (no token in the response)")
        return parts[1].encoded
    }
}
