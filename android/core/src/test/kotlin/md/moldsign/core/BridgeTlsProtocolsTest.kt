package md.moldsign.core

import javax.net.ssl.SSLContext
import javax.net.ssl.SSLServerSocket
import org.junit.Assert.*
import org.junit.Test

class BridgeTlsProtocolsTest {
    @Test fun listenerRejectsLegacyProtocolsWithoutChangingItsServerRole() {
        val context = SSLContext.getInstance("TLS").apply { init(null, null, null) }
        (context.serverSocketFactory.createServerSocket() as SSLServerSocket).use { socket ->
            configureBridgeTls(socket)
            assertFalse(socket.useClientMode)
            assertTrue(socket.enabledProtocols.contains("TLSv1.2"))
            assertTrue(socket.enabledProtocols.all { it == "TLSv1.2" || it == "TLSv1.3" })
        }
    }

    /** A provider socket that offers exactly [supported]; records what the bridge enables. */
    private class ProviderSocket(private val supported: Array<String>) : SSLServerSocket() {
        var enabled: Array<String> = supported
        var client = true
        override fun getSupportedProtocols() = supported
        override fun getEnabledProtocols() = enabled
        override fun setEnabledProtocols(protocols: Array<String>) { enabled = protocols }
        override fun getUseClientMode() = client
        override fun setUseClientMode(mode: Boolean) { client = mode }
        override fun getEnabledCipherSuites() = emptyArray<String>()
        override fun setEnabledCipherSuites(suites: Array<String>) = Unit
        override fun getSupportedCipherSuites() = emptyArray<String>()
        override fun setNeedClientAuth(need: Boolean) = Unit
        override fun getNeedClientAuth() = false
        override fun setWantClientAuth(want: Boolean) = Unit
        override fun getWantClientAuth() = false
        override fun setEnableSessionCreation(flag: Boolean) = Unit
        override fun getEnableSessionCreation() = true
    }

    @Test fun onlyModernProtocolsAreEnabledWhateverTheProviderOffers() {
        val android8 = ProviderSocket(arrayOf("SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"))
        configureBridgeTls(android8)
        assertArrayEquals(arrayOf("TLSv1.2"), android8.enabled)
        assertFalse(android8.client)

        val modern = ProviderSocket(arrayOf("TLSv1.3"))
        configureBridgeTls(modern)
        assertArrayEquals(arrayOf("TLSv1.3"), modern.enabled)

        val legacy = ProviderSocket(arrayOf("TLSv1", "TLSv1.1"))
        try { configureBridgeTls(legacy); fail("a provider without TLS 1.2 must not serve the bridge") }
        catch (error: IllegalArgumentException) { assertTrue(error.message!!.contains("TLS 1.2")) }
        assertArrayEquals(arrayOf("TLSv1", "TLSv1.1"), legacy.enabled)
    }
}
