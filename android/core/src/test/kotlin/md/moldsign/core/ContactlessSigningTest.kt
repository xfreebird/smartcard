package md.moldsign.core

import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Assert.*
import org.junit.Test

class ContactlessSigningTest {
    private fun simulated() = SimulatedCard(SpecFiles.cardCrypto, TestCertificates.mdQSign)
    private fun service(transport: ApduTransport, signed: () -> Unit = {}) =
        CardSigningService(TransportProvider { transport }, MutableStateFlow(ReaderState.NoReader), onCardSignature = signed)
    private fun sign(service: SigningService, expected: String) = service.signDigestInfo(
        DigestInfo.sha256("NFC diagnostic fixture".toByteArray()), "fixture.txt",
        Consent { ConsentResult.Pin(SimulatedCard.PIN.toCharArray()) }, expectedCertificateSha1 = expected)

    @Test fun publicIdentityAndSignatureShareOneConnection() {
        val card = simulated()
        val identity = ContactlessCertificateReader.readIdentity(card, null)
        assertFalse(card.plainLog.any { it.startsWith("0082") || it == "SM:20" })
        var signatures = 0
        val result = sign(service(card) { signatures++ }, identity.sha1Hex)
        assertArrayEquals(identity.der, result.certificateDer)
        assertEquals(512, result.signature.size)
        assertEquals(1, signatures)
        assertEquals(1, card.plainLog.count { it.startsWith("0082") })
        assertEquals(1, card.plainLog.count { it == "SM:20" })
        val verify = card.plainLog.indexOf("SM:20")
        assertEquals(listOf("SM:A4", "SM:A4", "SM:22", "SM:88"), card.plainLog.drop(verify + 1).filter { it.startsWith("SM:") })
        assertTrue(card.getResponses > 0)
    }

    @Test fun differentCardRejectedBeforeAuthenticationOrPin() {
        val card = simulated()
        assertThrows(CardError.CardChanged::class.java) {
            ContactlessCertificateReader.readIdentity(card, TestCertificates.mdTrustCa)
        }
        assertFalse(card.plainLog.any { it.startsWith("0082") || it == "SM:20" })
        assertEquals(3, card.attempts)
    }

    @Test fun wrongPinStopsAfterOneAttemptWithoutSigning() {
        val card = simulated().apply { verifyOverride = 0x63C2 }
        val identity = ContactlessCertificateReader.readIdentity(card, null)
        assertThrows(CardError.WrongPin::class.java) { sign(service(card), identity.sha1Hex) }
        assertEquals(1, card.plainLog.count { it == "SM:20" })
        assertFalse(card.plainLog.contains("SM:88"))
        assertEquals(1, card.plainLog.count { it.startsWith("0082") })
    }

    @Test fun eachSessionUsesFreshTerminalRandomness() {
        val first = simulated(); val second = simulated()
        CosmoXCard(first).authenticate(); CosmoXCard(second).authenticate()
        assertNotEquals(first.plainLog.first { it.startsWith("0082") }, second.plainLog.first { it.startsWith("0082") })
    }

    private fun intercept(card: SimulatedCard, exchange: (ByteArray, () -> ByteArray) -> ByteArray) = object : ApduTransport {
        override val readerName = "test"
        override fun transmit(apdu: ByteArray) = exchange(apdu) { card.transmit(apdu) }
        override fun close() {}
    }

    @Test fun d003LeadingBytesAreNotAssumedToBeATlvPrefix() {
        val card = simulated()
        val transport = intercept(card) { apdu, next ->
            val result = next()
            if (apdu.toHex() == "00B0000012") result.also { it[0] = 0x12; it[1] = 0x34 } else result
        }
        CosmoXCard(transport).authenticate()
    }

    @Test fun shortAuthenticationDataStopsBeforeExternalAuthentication() {
        val card = simulated()
        val transport = intercept(card) { apdu, next ->
            if (apdu.toHex() == "00B0000012") bytesOf(1, 2, 0x90, 0) else next()
        }
        assertThrows(CardError.Protocol::class.java) { CosmoXCard(transport).authenticate() }
        assertFalse(card.plainLog.any { it.startsWith("0082") })
    }

    @Test fun failedSetupSelectStopsBeforeExternalAuthentication() {
        val card = simulated()
        val transport = intercept(card) { apdu, next ->
            if (apdu.toHex() == "00A4020402D00400") bytesOf(0x6A, 0x82) else next()
        }
        assertThrows(CardError::class.java) { CosmoXCard(transport).authenticate() }
        assertFalse(card.plainLog.any { it.startsWith("0082") })
    }

    @Test fun shortPublicCertificateNeverAuthenticates() {
        val card = simulated()
        val transport = intercept(card) { apdu, next ->
            if (apdu.u8(1) == 0xB0) bytesOf(0x30, 0x90, 0) else next()
        }
        assertThrows(CardError.Protocol::class.java) { ContactlessCertificateReader.read(transport) }
        assertFalse(card.plainLog.any { it.startsWith("0082") })
    }

    @Test fun chainingHasABoundedCommandBudget() {
        var count = 0
        val transport = object : ApduTransport {
            override val readerName = "test"
            override fun transmit(apdu: ByteArray): ByteArray { count++; return bytesOf(0x61, 1) }
            override fun close() {}
        }
        assertThrows(CardError.Protocol::class.java) { ContactlessCertificateReader.read(transport) }
        assertEquals(8, count)
        count = 0
        assertThrows(CardError.Protocol::class.java) { CosmoXCard(transport).transmitFull(bytesOf(0, 0xC0, 0, 0, 0)) }
        assertEquals(64, count)
    }
}
