package md.moldsign.core

import com.sun.net.httpserver.HttpServer
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Test
import java.net.InetSocketAddress

/** HTTP behaviour of the PKI clients against a local server: the OCSP request, retries, unusable answers. */
class MdTrustServicesTest {
    private val statuses = ArrayDeque<Pair<Int, ByteArray>>()
    private val requests = mutableListOf<Pair<String?, ByteArray>>()
    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0).apply {
        createContext("/") { exchange ->
            requests += exchange.requestHeaders.getFirst("Content-Type") to exchange.requestBody.readBytes()
            val (status, body) = statuses.removeFirstOrNull() ?: (500 to ByteArray(0))
            exchange.sendResponseHeaders(status, if (body.isEmpty()) -1 else body.size.toLong())
            if (body.isNotEmpty()) exchange.responseBody.use { it.write(body) }
            exchange.close()
        }
        start()
    }
    private val url = "http://127.0.0.1:${server.address.port}/"
    private val trust = MdTrustServices(ocspUrl = url, tsaUrl = url, retryDelayMs = 0)
    private val response = ByteArray(300) { it.toByte() }

    @After
    fun tearDown() = server.stop(0)

    @Test
    fun ocspPostsTheRequestOfTheCertificate() {
        statuses += 200 to response

        val answer = trust.ocsp(TestCertificates.mdQSign, TestCertificates.mdTrustCa)

        assertArrayEquals(response, answer)
        assertEquals("application/ocsp-request", requests.single().first)
        assertArrayEquals(Revocation.ocspRequest(TestCertificates.mdQSign, TestCertificates.mdTrustCa), requests.single().second)
    }

    @Test
    fun aGatewayErrorIsRetriedOnce() {
        statuses += 502 to ByteArray(0)
        statuses += 200 to response

        assertArrayEquals(response, trust.ocsp(TestCertificates.mdQSign, TestCertificates.mdTrustCa))
        assertEquals(2, requests.size)
    }

    @Test
    fun aSecondFailureIsANetworkError() {
        statuses += 503 to ByteArray(0)
        statuses += 503 to ByteArray(0)

        try {
            trust.ocsp(TestCertificates.mdQSign, TestCertificates.mdTrustCa)
            fail("expected a network error")
        } catch (e: CardError.Network) {
            assertEquals("OCSP", e.service)
        }
        assertEquals(2, requests.size)
    }

    @Test
    fun aClientErrorIsNotRetriedAndAnErrorStatusBodyIsRejected() {
        statuses += 400 to ByteArray(0)
        try {
            trust.fetchCrl(url)
            fail("expected a network error")
        } catch (e: CardError.Network) {
            assertEquals("CRL", e.service)
        }
        assertEquals(1, requests.size)

        // OCSPResponse { status tryLater } is 5 bytes: nothing to reference
        statuses += 200 to byteArrayOf(0x30, 0x03, 0x0A, 0x01, 0x03)
        try {
            trust.ocsp(TestCertificates.mdQSign, TestCertificates.mdTrustCa)
            fail("expected a network error")
        } catch (e: CardError.Network) {
            assertEquals("OCSP (no usable response)", e.message?.removePrefix("Network error contacting "))
        }
    }
}
