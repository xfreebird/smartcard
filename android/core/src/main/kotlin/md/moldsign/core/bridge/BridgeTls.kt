package md.moldsign.core

import java.io.InputStream
import java.security.KeyStore
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext

/**
 * TLS identity of the bridge's HTTPS listener (`https://localhost.cts.md:18443`, docs/04, docs/06).
 *
 * The portal calls that origin from the browser; `localhost.cts.md` resolves to 127.0.0.1 and carries a publicly
 * issued certificate, so Chrome accepts it without a trust prompt. The identity is the one every MoldSign Desktop
 * install ships (SEC-07, D-03): `swift/MoldSignKit/Resources/localhost.p12`, packaged into this jar as
 * `md/moldsign/core/localhost.p12` by `processResources`. It is vendor-shipped, not a user secret, and the
 * listener binds to loopback only.
 */
object BridgeTls {
    // Keep resource lookup independent of the class/package name after R8 obfuscation.
    private const val RESOURCE = "/md/moldsign/core/localhost.p12"

    // Compiled into the vendor binary (docs/06); the same constant sits in the Swift Server.swift.
    private const val VENDOR_P12_PASSWORD = "u9mUvI9BNb1U9jSbpBKf36YWINVK5XX5KAzql3bILNnjscVfLn"

    /** The packaged vendor identity, or `null` when this build does not carry it. */
    fun vendorContext(): SSLContext? {
        val stream = BridgeTls::class.java.getResourceAsStream(RESOURCE) ?: return null
        return stream.use { context(it, VENDOR_P12_PASSWORD.toCharArray()) }
    }

    /** A server-side TLS context presenting the key and chain of the PKCS#12 [p12]. */
    fun context(p12: InputStream, password: CharArray): SSLContext {
        val store = KeyStore.getInstance("PKCS12")
        store.load(p12, password)
        val keys = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
        keys.init(store, password)
        return SSLContext.getInstance("TLS").apply { init(keys.keyManagers, null, null) }
    }
}
