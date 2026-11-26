package md.moldsign.app.nfc

import android.app.Activity
import android.app.Application
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.flow.MutableStateFlow
import md.moldsign.app.application.ConsentBroker
import md.moldsign.app.application.DocumentDataProvider
import md.moldsign.app.application.DocumentOutputStore
import md.moldsign.app.application.PickedDocument
import md.moldsign.app.application.SignDocuments
import md.moldsign.app.application.SignItem
import md.moldsign.core.BridgeCard
import md.moldsign.core.CardError
import md.moldsign.core.CertificateSummary
import md.moldsign.core.ChainCerts
import md.moldsign.core.ConsentRequest
import md.moldsign.core.ConsentResult
import md.moldsign.core.Document
import md.moldsign.core.ReaderState
import md.moldsign.core.SignResult
import md.moldsign.core.SigningService
import md.moldsign.core.SigningStep
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.concurrent.atomic.AtomicReference

/**
 * NFC document signing and the browser coordinator over a simulated contactless card that serves a public
 * certificate and refuses authentication: the identity is bound before any PIN command, and every failure
 * stops the batch without a retry.
 */
@RunWith(RobolectricTestRunner::class)
@Config(application = Application::class)
class NfcFlowsTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    private val der = ChainCerts.chain.first()
    private val radio = FakeNfcRadio()
    private val controller = NfcSigningController(radio, app, scanTimeoutMs = 2_000)
    private val broker = ConsentBroker()

    /** A card that answers SELECT and READ BINARY of EF0001 and refuses everything else (no authentication). */
    private fun card(certificate: ByteArray = der): FakeIsoDep = FakeIsoDep { apdu ->
        val ok = byteArrayOf(0x90.toByte(), 0)
        when (apdu[1].toInt() and 0xFF) {
            0xA4 -> ok
            0xB0 -> {
                val offset = ((apdu[2].toInt() and 0xFF) shl 8) or (apdu[3].toInt() and 0xFF)
                val length = apdu[4].toInt() and 0xFF
                certificate.copyOfRange(offset, minOf(certificate.size, offset + length)) + ok
            }
            else -> byteArrayOf(0x69, 0x82.toByte())
        }
    }

    private val inputs = object : DocumentDataProvider {
        override fun document(item: PickedDocument) = Document(item.name, "%PDF-1.7\n%%EOF\n".toByteArray())
    }
    private val outputs = DocumentOutputStore { _, _, _ -> fail("nothing is saved without a signature"); Uri.EMPTY }

    private fun item(name: String) = SignItem(PickedDocument(Uri.parse("test://$name"), name, 10, "application/pdf"))

    /** Answers the PIN dialog from another thread, as the UI would. */
    private fun answerPin(pin: String?) = Thread {
        val end = System.currentTimeMillis() + 5_000
        while (broker.pending.value == null && System.currentTimeMillis() < end) Thread.sleep(5)
        broker.pending.value?.answer(if (pin == null) ConsentResult.Cancelled else ConsentResult.Pin(pin.toCharArray()))
    }.apply { start() }

    @Test fun authenticationFailureStopsTheBatchAfterBindingTheCard() {
        radio.cardOnEnable = FakeTag("eid", card())
        controller.resumed(activity)
        val events = mutableListOf<SignDocuments.Event>()
        val identified = AtomicReference<CertificateSummary?>()
        answerPin("1234")
        try {
            NfcSignDocuments(controller, broker, inputs, outputs).execute(listOf(item("a.pdf"), item("b.pdf")), null, identified::set, events::add)
            fail("the simulated card refuses authentication")
        } catch (_: CardError) {}
        assertEquals(CertificateSummary.parse(der).sha1Hex, identified.get()?.sha1Hex)
        // One document started and failed; the second never started and nothing was retried.
        assertEquals(listOf("Started", "Failed"), events.map { it.javaClass.simpleName })
        assertTrue(radio.calls.first() == "enable")
        assertNull(controller.phase.value)
    }

    @Test fun aDifferentCardIsRejectedBeforeAnyPinCommand() {
        val iso = card()
        radio.cardOnEnable = FakeTag("eid", iso)
        controller.resumed(activity)
        val expected = CertificateSummary.parse(ChainCerts.chain.last())
        answerPin("1234")
        try {
            NfcSignDocuments(controller, broker, inputs, outputs).execute(listOf(item("a.pdf")), expected, {}, {})
            fail("card changed")
        } catch (_: CardError.CardChanged) {}
        assertTrue(iso.commands.none { (it[1].toInt() and 0xFF) == 0x20 })
    }

    @Test fun cancelledPinNeverEnablesTheAntenna() {
        controller.resumed(activity)
        answerPin(null)
        try {
            NfcSignDocuments(controller, broker, inputs, outputs).execute(listOf(item("a.pdf")), null, {}, {})
            fail("cancelled")
        } catch (_: CardError.Cancelled) {}
        assertTrue(radio.calls.isEmpty())
        val broken = CertificateSummary.parse(der).copy(der = null)
        answerPin("1234")
        try {
            NfcSignDocuments(controller, broker, inputs, outputs).execute(listOf(item("a.pdf")), broken, {}, {})
            fail("selected identity without certificate")
        } catch (_: CardError.Protocol) {}
    }

    @Test fun browserCoordinatorIdentifiesAndGuardsRequests() {
        val coordinator = NfcBrowserCoordinator(controller, app)
        assertTrue(coordinator.enabled.value)
        assertTrue(coordinator.cards().isEmpty())
        radio.cardOnEnable = FakeTag("eid", card())
        controller.resumed(activity)
        coordinator.identify()
        radio.representOnIgnore = FakeTag("eid-again", card())
        val identity = requireNotNull(coordinator.certificate.value)
        assertEquals(listOf("nfc:${identity.sha1Hex}"), coordinator.cards().map { it.readerId })
        coordinator.seed(CertificateSummary.parse(ChainCerts.chain.last()))
        assertEquals(identity.sha1Hex, coordinator.certificate.value?.sha1Hex)

        val request = ConsentRequest("https://msign.gov.md", listOf("doc.pdf"), "PAdES-T", identity)
        val fallback = object : SigningService by NoSigning {}
        // A reader card is refused while NFC is the browser method.
        try {
            coordinator.sign(BridgeCard("usb-1", identity), request, { ConsentResult.Cancelled }, fallback) { _, _ -> error("unused") }
            fail("reader card while NFC is selected")
        } catch (_: CardError.Cancelled) {}
        // A cancelled PIN stops before the antenna opens again.
        val calls = radio.calls.size
        try {
            coordinator.sign(BridgeCard("nfc:${identity.sha1Hex}", identity), request, { ConsentResult.Cancelled }, fallback) { _, _ -> error("unused") }
            fail("cancelled")
        } catch (_: CardError.Cancelled) {}
        assertEquals(calls, radio.calls.size)
        // With a PIN, the card is read again and bound before the (refused) authentication.
        try {
            coordinator.sign(BridgeCard("nfc:${identity.sha1Hex}", identity), request, { ConsentResult.Pin("1234".toCharArray()) }, fallback) { service, consent ->
                service.signPdf(Document("doc.pdf", "%PDF".toByteArray()), consent)
            }
            fail("authentication refused")
        } catch (_: CardError) {}

        coordinator.forget(identity.sha1Hex)
        assertNull(coordinator.certificate.value)
        coordinator.setEnabled(false)
        assertFalse(NfcBrowserCoordinator(controller, app).enabled.value)
        val result = coordinator.sign(BridgeCard("usb-1", identity), request, { ConsentResult.Cancelled }, fallback) { _, _ ->
            SignResult(ByteArray(1), identity, "PAdES-T")
        }
        assertEquals("PAdES-T", result.format)
        try {
            coordinator.sign(BridgeCard("nfc:x", identity), request, { ConsentResult.Cancelled }, fallback) { _, _ -> error("unused") }
            fail("NFC disabled")
        } catch (_: CardError.Cancelled) {}
        coordinator.select(identity)
        assertTrue(coordinator.enabled.value)
    }

    private object NoSigning : SigningService {
        override val readerState = MutableStateFlow<ReaderState>(ReaderState.NoReader)
        override val progress = MutableStateFlow(SigningStep.Idle)
        override fun certificate(reader: String?) = throw CardError.NoReader()
        override fun signPdf(input: Document, consent: md.moldsign.core.Consent, requester: String?, reader: String?, expectedCertificateSha1: String?) = throw CardError.NoReader()
        override fun signXades(files: List<Document>, level: md.moldsign.core.XadesLevel, packaging: md.moldsign.core.XadesPackaging, consent: md.moldsign.core.Consent,
            requester: String?, reader: String?, expectedCertificateSha1: String?, digest: md.moldsign.core.XadesDigest) = throw CardError.NoReader()
        override fun signDigestInfo(digestInfo: ByteArray, documentName: String, consent: md.moldsign.core.Consent, requester: String?,
            reader: String?, expectedCertificateSha1: String?) = throw CardError.NoReader()
        override fun verify(file: Document, detachedDocuments: List<Document>) = emptyList<md.moldsign.core.ValidationReport>()
    }
}
