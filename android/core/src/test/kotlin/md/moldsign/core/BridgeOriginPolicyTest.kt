package md.moldsign.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.net.Socket

class BridgeOriginPolicyTest {
    private val specText = SpecFiles.read("spec/bridge/allowed-origins.properties")
    private val policy = BridgeOriginPolicy.fromProperties(specText)

    @Test
    fun readsEveryValueIncludingDuplicateKeys() {
        val values = BridgeOriginPolicy.propertyValues(specText)
        val nonComment = specText.lines().count { it.isNotBlank() && !it.trimStart().startsWith("#") }
        assertEquals(nonComment, values.size)
        assertTrue("first gov= value kept", "https://msign.gov.md" in values)
        assertTrue("second gov= value kept", "*.gov.md" in values)
    }

    @Test
    fun bundledResourceMatchesSpecFile() {
        assertEquals(policy.regexes.map { it.pattern }, BridgeOriginPolicy.bundled().regexes.map { it.pattern })
    }

    @Test
    fun vendorConversion() {
        assertEquals("""https://msign\.gov\.md""", BridgeOriginPolicy.vendorPatternToRegex("https://msign.gov.md").pattern)
        assertEquals(""".*\.gov\.md""", BridgeOriginPolicy.vendorPatternToRegex("*.gov.md").pattern)
        assertEquals("""a.?b""", BridgeOriginPolicy.vendorPatternToRegex("a?b").pattern)
    }

    @Test
    fun portalAllowed() {
        assertTrue(policy.isAllowed("https://msign.gov.md", null))
        assertTrue(policy.isAllowed("https://mpass.gov.md", null))
        assertTrue(policy.isAllowed("https://sgre.w.mcb.md", null))
        assertTrue(policy.isAllowed("http://localhost", null))
    }

    @Test
    fun foreignOriginDenied() {
        assertFalse(policy.isAllowed("https://evil.example", null))
        assertFalse("header does not rescue a bad Origin", policy.isAllowed("https://evil.example", "DesktopSuiteClient"))
        assertFalse("full match required", policy.isAllowed("https://msign.gov.md.evil.example", null))
        assertFalse(policy.isAllowed("http://localhost:3000", null))
        assertFalse(policy.isAllowed("", null))
        assertFalse(policy.isAllowed("null", null))
    }

    @Test
    fun nullOriginWithDesktopHeaderAllowed() {
        assertTrue(policy.isAllowed(null, "DesktopSuiteClient"))
    }

    @Test
    fun nullOriginWithoutHeaderDenied() {
        assertFalse(policy.isAllowed(null, null))
        assertFalse(policy.isAllowed(null, "desktopsuiteclient"))
    }
}

class BridgeServerTest {
    private val policy = BridgeOriginPolicy.fromProperties(SpecFiles.read("spec/bridge/allowed-origins.properties"))

    private fun request(method: String, path: String, vararg headers: Pair<String, String>) =
        BridgeRequest(method, path, null, headers.associate { it.first.lowercase() to it.second }, ByteArray(0))

    @Test
    fun preflightFromPortalGetsCorsAndPrivateNetwork() {
        val server = BridgeServer(policy)
        val r = server.respond(request("OPTIONS", "/certificates", "Origin" to "https://msign.gov.md", "Access-Control-Request-Private-Network" to "true"))
        val h = r.headers.toMap()
        assertEquals(200, r.status)
        assertEquals("https://msign.gov.md", h["Access-Control-Allow-Origin"])
        assertEquals("true", h["Access-Control-Allow-Private-Network"])
        assertEquals("GET, POST, OPTIONS", h["Access-Control-Allow-Methods"])
    }

    @Test
    fun foreignOriginGets403WithoutCors() {
        val r = BridgeServer(policy).respond(request("GET", "/certificates", "Origin" to "https://evil.example"))
        assertEquals(403, r.status)
        assertNull(r.headers.toMap()["Access-Control-Allow-Origin"])
    }

    @Test
    fun certificatesOverRealSocket() {
        BridgeServer(policy, port = 0).use { server ->
            val port = server.start()
            val ok = rawHttp(port, "GET /certificates HTTP/1.1\r\nHost: 127.0.0.1\r\nOrigin: https://msign.gov.md\r\n\r\n")
            assertTrue(ok, ok.startsWith("HTTP/1.1 200 OK"))
            assertTrue(ok.contains("Access-Control-Allow-Origin: https://msign.gov.md"))
            assertTrue(ok.endsWith("""{"certificateModel":[]}"""))

            val desktop = rawHttp(port, "GET /certificates HTTP/1.1\r\nHost: 127.0.0.1\r\nmoldSign: DesktopSuiteClient\r\n\r\n")
            assertTrue(desktop, desktop.startsWith("HTTP/1.1 200 OK"))
            assertFalse(desktop.contains("Access-Control-Allow-Origin"))

            val anonymous = rawHttp(port, "GET /certificates HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n")
            assertTrue(anonymous, anonymous.startsWith("HTTP/1.1 403"))

            val notYet = rawHttp(port, "POST /sign/data HTTP/1.1\r\nHost: 127.0.0.1\r\nOrigin: https://msign.gov.md\r\nContent-Length: 2\r\n\r\n{}")
            assertTrue(notYet, notYet.startsWith("HTTP/1.1 501"))
        }
    }

    private fun rawHttp(port: Int, request: String): String =
        Socket("127.0.0.1", port).use { s ->
            s.soTimeout = 5000
            s.getOutputStream().write(request.toByteArray(Charsets.ISO_8859_1))
            s.getOutputStream().flush()
            s.getInputStream().readBytes().toString(Charsets.ISO_8859_1)
        }
}
