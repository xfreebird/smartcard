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
}
