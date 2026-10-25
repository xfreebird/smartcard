package md.moldsign.core

/**
 * The CA chain every CMS embeds next to the signer certificate (the same set the MoldSign app writes): the MDQSign
 * issuing CA and the self-signed mdtrustca root. Public certificates, DER, bundled as jar resources
 * (same bytes as `ChainCerts.swift`).
 */
object ChainCerts {
    val mdQSign: ByteArray by lazy { resource("mdqsign.der") }
    val mdTrustCA: ByteArray by lazy { resource("mdtrustca.der") }

    /** As the signers take it: the issuing CA first, then the root. */
    val chain: List<ByteArray> get() = listOf(mdQSign, mdTrustCA)

    private fun resource(name: String): ByteArray =
        (ChainCerts::class.java.getResourceAsStream("/md/moldsign/core/$name") ?: error("Missing resource $name"))
            .use { it.readBytes() }
}
