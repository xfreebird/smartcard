package md.moldsign.core

import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/**
 * Identity guard before VERIFY (docs/09 §3.1b, SEC-08): the card's certificate is read and its SHA-1 compared
 * with the card the PIN / consent / selection is for. A swapped card fails with [CardError.CardChanged] before
 * the PIN is asked for or sent, so it can never burn a retry on the wrong card.
 *
 * "Card A" and "card B" are the simulator serving two different public certificates ([TestCertificates]).
 */
class IdentityGuardTest {
    private val v = SpecFiles.cardCrypto
    private val shaA = Sha.sha1(TestCertificates.mdQSign).toHex()
    private val shaB = Sha.sha1(TestCertificates.mdTrustCa).toHex()

    @Test
    fun prepareForSigningVerifiesThePinOnTheExpectedCard() {
        val cardA = SimulatedCard(v, TestCertificates.mdQSign)
        val card = CosmoXCard(cardA).apply { authenticate() }

        val cert = card.prepareForSigning(SimulatedCard.PIN.toCharArray(), shaA.lowercase()) // case-insensitive

        assertArrayEquals(TestCertificates.mdQSign, cert)
        assertTrue("VERIFY was sent", "SM:20" in cardA.plainLog)
        assertTrue("certificate read before VERIFY", cardA.plainLog.indexOf("SM:B0") < cardA.plainLog.indexOf("SM:20"))
        assertEquals(512, card.sign(DigestInfo.sha256("abc".toByteArray())).size)
    }

    @Test
    fun swappedCardFailsBeforeVerify() {
        val cardB = SimulatedCard(v, TestCertificates.mdTrustCa) // the user selected A, B is in the reader
        val card = CosmoXCard(cardB).apply { authenticate() }
        try {
            card.prepareForSigning(SimulatedCard.PIN.toCharArray(), shaA)
            fail("expected CardChanged")
        } catch (e: CardError.CardChanged) {
            assertEquals(shaA, e.expectedSha1)
            assertEquals(shaB, e.actualSha1)
        }
        assertTrue("the certificate was read", "SM:B0" in cardB.plainLog)
        assertFalse("no VERIFY reached card B", "SM:20" in cardB.plainLog)
        assertEquals("card B's retry counter is untouched", 3, cardB.attempts)
    }

    @Test
    fun noExpectationSkipsTheGuard() {
        CosmoXCard.checkIdentity(TestCertificates.mdTrustCa, null)
        CosmoXCard.checkIdentity(TestCertificates.mdTrustCa, " ${shaB.lowercase()} ")
    }

    @Test
    fun signingServiceRefusesASwappedCardBeforeAskingForThePin() {
        val cardB = SimulatedCard(v, TestCertificates.mdTrustCa)
        val service = CardSigningService(TransportProvider { cardB }, MutableStateFlow(ReaderState.NoReader))
        var consentAsked = false
        try {
            service.signDigestInfo(
                DigestInfo.sha256("contract".toByteArray()),
                "contract.pdf",
                Consent { consentAsked = true; ConsentResult.Pin(SimulatedCard.PIN.toCharArray()) },
                expectedCertificateSha1 = shaA,
            )
            fail("expected CardChanged")
        } catch (e: CardError.CardChanged) {
            assertEquals(shaB, e.actualSha1)
        }
        assertFalse("the PIN sheet never opened for the wrong card", consentAsked)
        assertFalse("no VERIFY reached card B", "SM:20" in cardB.plainLog)
        assertEquals(3, cardB.attempts)
        assertEquals(SigningStep.Idle, service.progress.value)
    }

    @Test
    fun signingServiceSignsWithTheSelectedReadersCard() {
        val cardA = SimulatedCard(v, TestCertificates.mdQSign)
        val cardB = SimulatedCard(v, TestCertificates.mdTrustCa)
        val readers = mapOf("usb-a" to cardA, "usb-b" to cardB)
        val service = CardSigningService(
            TransportProvider { reader -> readers[reader] ?: throw CardError.NoReader() },
            MutableStateFlow(ReaderState.NoReader),
        )
        assertEquals(shaB, service.certificate("usb-b").sha1Hex)

        val asked = mutableListOf<ConsentRequest>()
        val di = DigestInfo.sha256("contract".toByteArray())
        val result = service.signDigestInfo(
            di,
            "contract.pdf",
            Consent { asked += it; ConsentResult.Pin(SimulatedCard.PIN.toCharArray()) },
            reader = "usb-a",
            expectedCertificateSha1 = shaA,
        )
        assertArrayEquals(TestCertificates.mdQSign, result.certificateDer)
        assertEquals(512, result.signature.size)
        assertEquals("one PIN request, for card A", listOf(shaA), asked.map { it.certificate.sha1Hex })
        assertTrue("SM:20" in cardA.plainLog)
        assertFalse("card B was never asked to sign", "SM:20" in cardB.plainLog)
        assertEquals(SigningStep.Done, service.progress.value)
    }
}
