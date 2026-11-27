package md.moldsign.core

import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Phase TOK: the Kotlin table equals spec/tokens/token-families.json, its vectors hold, and the gate sends no APDU. */
class TokenRecognitionTest {
    private val spec: Any? by lazy { MiniJson.parse(SpecFiles.read("spec/tokens/token-families.json")) }

    @Test fun tableMatchesSpec() {
        val fromSpec = spec.list("families").flatMap { family ->
            val id = family.str("id")
            assertEquals(family.str("name"), TokenFamily.values().firstOrNull { it.id == id }?.displayName)
            family.list("patterns").map { "$id ${it.str("atr")} ${it.str("mask")}" }
        }
        val table = TokenRecognizer.patterns.map { (family, p) -> "${family.id} ${Hex.encode(p.atr)} ${Hex.encode(p.mask)}" }
        assertEquals("regenerate TokenRecognizer.patterns from spec/tokens/token-families.json", fromSpec, table)
    }

    @Suppress("UNCHECKED_CAST")
    @Test fun vectors() {
        val vectors = spec.list("vectors")
        assertTrue(vectors.isNotEmpty())
        for (vector in vectors) {
            val v = vector as Map<String, Any?>
            val atr = Hex.decode(v["atr"] as String)
            assertEquals(v["comment"] as String, v["family"] as String?, TokenRecognizer.family(atr)?.id)
        }
        assertNull(TokenRecognizer.family(null))
    }

    @Test fun recognizedTokenGetsNoApduWhenEnabled() {
        val token = RecordingTransport(Hex.decode("3B9F958131FE9F006646530500000071DF000000000000"))
        val service = CardSigningService(TransportProvider { token }, MutableStateFlow(ReaderState.NoReader),
            experimentalTokens = { true })
        val failure = runCatching { service.certificate("token") }.exceptionOrNull()
        assertEquals(TokenFamily.EPASS2003, (failure as? UnsupportedTokenException)?.family)
        assertTrue("a recognized token must not receive IAS/ECC commands", token.sent.isEmpty())
        assertTrue(token.closed)
    }

    @Test fun disabledKeepsTheEidPath() {
        val token = RecordingTransport(Hex.decode("3B9F958131FE9F006646530500000071DF000000000000"))
        val service = CardSigningService(TransportProvider { token }, MutableStateFlow(ReaderState.NoReader))
        val failure = runCatching { service.certificate("token") }.exceptionOrNull()
        assertTrue("6A82 from the IAS application select fails as before", failure != null)
        assertFalse("off by default: no token recognition", failure is UnsupportedTokenException)
        assertFalse("off: the card is treated as an eID, as before", token.sent.isEmpty())
    }

    @Test fun eidIsNotATokenWhenEnabled() {
        val eid = RecordingTransport(Hex.decode("3BDF96008131FE4580738421E0574D44415F415350810F78"))
        val service = CardSigningService(TransportProvider { eid }, MutableStateFlow(ReaderState.NoReader),
            experimentalTokens = { true })
        val failure = runCatching { service.certificate("eid") }.exceptionOrNull()
        assertTrue(failure != null)
        assertFalse("the CosmoX eID is never a token", failure is UnsupportedTokenException)
        assertFalse(eid.sent.isEmpty())
    }

    /** Answers every APDU with 6A82, like a token asked for the IAS/ECC application. */
    private class RecordingTransport(private val atr: ByteArray) : ApduTransport {
        override val readerName = "Recording reader"
        val sent = mutableListOf<ByteArray>()
        var closed = false
        override fun transmit(apdu: ByteArray): ByteArray { sent += apdu; return byteArrayOf(0x6A, 0x82.toByte()) }
        override fun answerToReset(): ByteArray = atr
        override fun close() { closed = true }
    }
}
