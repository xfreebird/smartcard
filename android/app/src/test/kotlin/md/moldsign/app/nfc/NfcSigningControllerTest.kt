package md.moldsign.app.nfc

import android.app.Activity
import android.app.Application
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import md.moldsign.core.CardError
import md.moldsign.core.SigningStep
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File
import java.io.IOException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** A simulated adapter: records every reader-mode call and presents cards on demand. */
internal class FakeNfcRadio(override var enabled: Boolean = true) : NfcRadio {
    override val available = true
    val calls = mutableListOf<String>()
    @Volatile var onTag: ((NfcTagHandle) -> Unit)? = null
    /** Presented as soon as reader mode is enabled (a card already held at the antenna). */
    var cardOnEnable: NfcTagHandle? = null
    val enabledLatch = CountDownLatch(1)
    var tagStillPresent = true
    /** Like Android in reader mode: an ignored card that is still in the field is discovered again. */
    var representOnIgnore: NfcTagHandle? = null

    override fun enable(host: Activity, onTag: (NfcTagHandle) -> Unit) {
        synchronized(calls) { calls += "enable" }
        this.onTag = onTag
        enabledLatch.countDown()
        cardOnEnable?.let(onTag)
    }
    override fun disable(host: Activity) { synchronized(calls) { calls += "disable" } }
    override fun ignore(tag: NfcTagHandle): Boolean {
        synchronized(calls) { calls += "ignore:${(tag as FakeTag).name}" }
        representOnIgnore?.let { again -> onTag?.invoke(again) }
        return tagStillPresent
    }
    fun present(tag: NfcTagHandle) = requireNotNull(onTag) { "reader mode is off" }(tag)
}

internal open class FakeIsoDep(private val reply: (ByteArray) -> ByteArray = { byteArrayOf(0x90.toByte(), 0) }) : IsoDepLink {
    override val maxTransceiveLength = 261
    override var timeout = 0
    var connected = false
    var closed = false
    var failConnect = false
    val commands = mutableListOf<ByteArray>()
    override fun connect() { if (failConnect) throw IOException("lost"); connected = true }
    override fun transceive(apdu: ByteArray): ByteArray { commands += apdu; return reply(apdu) }
    override fun close() { closed = true }
}

internal class FakeTag(val name: String, private val iso: FakeIsoDep?) : NfcTagHandle {
    var opened = 0
    override fun isoDep(): IsoDepLink? { opened++; return iso }
}

@RunWith(RobolectricTestRunner::class)
@Config(application = Application::class)
class NfcSigningControllerTest {
    private val context = ApplicationProvider.getApplicationContext<Application>()
    private val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    private val radio = FakeNfcRadio()
    private val controller = NfcSigningController(radio, context, scanTimeoutMs = 200)

    private fun diagnostics(): List<String> =
        File(context.cacheDir, "nfc-diagnostics").listFiles().orEmpty().map { it.readText() }

    @Test fun successfulSignatureKeepsReaderModeUntilTheActivityPauses() {
        val iso = FakeIsoDep { byteArrayOf(0x01, 0x90.toByte(), 0x00) }
        radio.cardOnEnable = FakeTag("eid", iso)
        controller.resumed(activity)

        val session = controller.open()
        assertTrue(iso.connected)
        assertEquals(8_000, iso.timeout)
        assertEquals(NfcSigningController.Phase.Reading, controller.phase.value)
        assertArrayEquals(byteArrayOf(0x01, 0x90.toByte(), 0x00), session.transmit(byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00)))
        session.step(SigningStep.Signing)
        assertEquals(SigningStep.Signing, controller.progress.value)
        session.identified()
        assertEquals(NfcSigningController.Phase.Signing, controller.phase.value)

        session.cardSigned()
        // The card is released, the NFC window closes, but reader mode keeps holding the card in the field.
        assertTrue(iso.closed)
        assertNull(controller.phase.value)
        assertTrue(controller.readerModeActive)
        assertEquals(listOf("enable"), radio.calls)
        session.documentSaved()
        session.close()

        // A rediscovery of the same card goes nowhere: no session, no system dispatch.
        radio.present(FakeTag("eid-again", FakeIsoDep()))
        assertEquals(listOf("enable"), radio.calls)

        controller.paused(activity)
        assertEquals(listOf("enable", "ignore:eid-again", "disable"), radio.calls)
        assertFalse(controller.readerModeActive)
        assertTrue(diagnostics().any { "\"document_saved\"" in it && "reader_mode_held" in it })
    }

    @Test fun failureAfterTheCardWasSeenAlsoHoldsReaderMode() {
        val iso = FakeIsoDep { throw IOException("tag lost") }
        radio.cardOnEnable = FakeTag("eid", iso)
        controller.resumed(activity)
        val session = controller.open()
        try {
            session.transmit(byteArrayOf(0, 0x20, 0, 0x03))
            fail("transport loss must surface")
        } catch (_: NfcConnectionLost) {}
        session.failure(NfcConnectionLost())
        assertTrue(iso.closed)
        assertTrue(controller.readerModeActive)
        assertEquals(listOf("enable"), radio.calls)
        assertTrue(diagnostics().any { "\"failed\"" in it && "connection_lost" in it })
    }

    @Test fun timeoutWithoutCardReleasesReaderMode() {
        controller.resumed(activity)
        try {
            controller.open()
            fail("no card was presented")
        } catch (_: NfcScanTimeout) {}
        assertEquals(listOf("enable", "disable"), radio.calls)
        assertFalse(controller.readerModeActive)
        assertNull(controller.phase.value)
    }

    @Test fun unsupportedCardIsHeldSoTheSystemDoesNotDispatchIt() {
        radio.cardOnEnable = FakeTag("transit", null)
        controller.resumed(activity)
        try {
            controller.open()
            fail("not an ISO-DEP card")
        } catch (_: NfcUnsupportedCard) {}
        assertTrue(controller.readerModeActive)
        assertEquals(listOf("enable"), radio.calls)
    }

    @Test fun lostConnectionDuringConnectIsReported() {
        val iso = FakeIsoDep().apply { failConnect = true }
        radio.cardOnEnable = FakeTag("eid", iso)
        controller.resumed(activity)
        try {
            controller.open()
            fail("connect failed")
        } catch (_: NfcConnectionLost) {}
        assertTrue(controller.readerModeActive)
    }

    @Test fun cancelWhileWaitingStopsTheScanAndReleasesReaderMode() {
        val slow = NfcSigningController(radio, context, scanTimeoutMs = 60_000)
        slow.resumed(activity)
        val outcome = AtomicReference<Throwable?>()
        val worker = Thread {
            try { slow.open() } catch (error: Throwable) { outcome.set(error) }
        }
        worker.start()
        // The worker posts reader-mode activation to the main thread.
        while (radio.enabledLatch.count > 0) {
            shadowOf(Looper.getMainLooper()).idle()
            Thread.sleep(5)
        }
        assertEquals(NfcSigningController.Phase.Waiting, slow.phase.value)
        slow.cancel()
        worker.join(60_000)
        assertFalse(worker.isAlive)
        assertTrue(outcome.get() is CardError.Cancelled)
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(listOf("enable", "disable"), radio.calls)
        assertNull(slow.phase.value)
        // A late callback cannot reactivate the cancelled scan.
        radio.present(FakeTag("late", FakeIsoDep()))
        assertNull(slow.phase.value)
    }

    @Test fun pausingDuringAScanCancelsItAndReleasesTheCard() {
        val iso = FakeIsoDep()
        radio.cardOnEnable = FakeTag("eid", iso)
        controller.resumed(activity)
        val session = controller.open()
        controller.paused(activity)
        assertTrue(iso.closed)
        try {
            session.transmit(byteArrayOf(0, 0, 0, 0))
            fail("cancelled session must not reach the card")
        } catch (_: CardError.Cancelled) {}
        assertEquals(listOf("enable", "ignore:eid", "disable"), radio.calls)
        // No foreground host any more: a new scan is refused instead of enabling reader mode.
        try { controller.open(); fail("paused") } catch (_: CardError.Cancelled) {}
    }

    @Test fun batchDocumentsEachGetAFreshPresentation() {
        // The worker waits for the presented card; only a broken flow may run into the scan timeout.
        val controller = NfcSigningController(radio, context, scanTimeoutMs = 60_000)
        val first = FakeIsoDep()
        radio.cardOnEnable = FakeTag("eid", first)
        controller.resumed(activity)
        controller.open().use { it.cardSigned() }

        // Second document: the held card is handed back to the platform and presented again.
        val second = FakeIsoDep()
        val rediscovered = FakeTag("eid-2", second)
        val latch = CountDownLatch(1)
        val result = AtomicReference<NfcSigningController.Session?>()
        val worker = Thread { result.set(controller.open()); latch.countDown() }
        worker.start()
        while (!radio.calls.contains("ignore:eid")) {
            shadowOf(Looper.getMainLooper()).idle()
            Thread.sleep(5)
        }
        radio.present(rediscovered)
        assertTrue(latch.await(60, TimeUnit.SECONDS))
        assertTrue(second.connected)
        assertEquals(listOf("enable", "ignore:eid"), radio.calls)
        result.get()!!.close()
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(controller.readerModeActive)
    }

    @Test fun preconditionsRefuseToOpen() {
        try { controller.open(); fail("no activity") } catch (_: CardError.Cancelled) {}
        controller.resumed(activity)
        radio.enabled = false
        try { controller.open(); fail("NFC off") } catch (_: NfcUnavailable) {}
        assertTrue(controller.available)
        assertFalse(controller.enabled)
        assertTrue(radio.calls.isEmpty())
    }

    @Test fun oversizedCommandAndConcurrentOpenAreRejected() {
        radio.cardOnEnable = FakeTag("eid", FakeIsoDep())
        controller.resumed(activity)
        val session = controller.open()
        try { session.transmit(ByteArray(300)); fail("too large") } catch (_: CardError.Protocol) {}
        try { controller.open(); fail("one session at a time") } catch (_: IllegalStateException) {}
        session.close()
        session.close()
        try { session.transmit(ByteArray(4)); fail("closed") } catch (_: CardError.Cancelled) {}
    }

    @Test fun readerModeFailureEndsTheSession() {
        val failing = object : NfcRadio {
            override val available = true
            override val enabled = true
            override fun enable(host: Activity, onTag: (NfcTagHandle) -> Unit) = throw IllegalStateException("not resumed")
            override fun disable(host: Activity) = Unit
            override fun ignore(tag: NfcTagHandle) = false
        }
        val controller = NfcSigningController(failing, context, scanTimeoutMs = 1_000)
        controller.resumed(activity)
        try { controller.open(); fail("reader mode failed") } catch (_: CardError.Cancelled) {}
        assertFalse(controller.readerModeActive)
    }

    @Test fun androidRadioWithoutAdapterIsUnavailable() {
        val radio = AndroidNfcRadio(null)
        assertFalse(radio.available)
        assertFalse(radio.enabled)
        assertFalse(radio.ignore(FakeTag("x", null)))
        radio.disable(activity)
        assertFalse(NfcSigningController(context).available)
    }

    @Test fun statusWordsAndShortCommandsReachTheDiagnostics() {
        radio.cardOnEnable = FakeTag("eid", FakeIsoDep { byteArrayOf(0x69, 0x82.toByte()) })
        controller.resumed(activity)
        val session = controller.open()
        assertArrayEquals(byteArrayOf(0x69, 0x82.toByte()), session.transmit(byteArrayOf(0)))
        session.failure(CardError.UnexpectedStatus(0x6982, "VERIFY"))
        assertTrue(diagnostics().any { "\"UnexpectedStatus\"" in it && "27010" in it })
        // Pausing another activity leaves this host and its reader mode alone.
        controller.paused(Robolectric.buildActivity(Activity::class.java).setup().get())
        assertTrue(controller.readerModeActive)
    }

    /** A fresh adapter and controller whose card is [card] (built with access to that controller). */
    private fun scan(card: (NfcSigningController) -> NfcTagHandle): Throwable? {
        val radio = FakeNfcRadio()
        val controller = NfcSigningController(radio, context, scanTimeoutMs = 60_000)
        radio.cardOnEnable = card(controller)
        controller.resumed(activity)
        return runCatching { controller.open() }.exceptionOrNull()
    }

    @Test fun cancelDuringConnectNeverReachesTheCard() {
        // Cancelled while the ISO-DEP object is fetched: the connection is never kept.
        assertTrue(scan { controller -> object : NfcTagHandle {
            override fun isoDep(): IsoDepLink { controller.cancel(); return FakeIsoDep() }
        } } is CardError.Cancelled)

        // Cancelled while connect() is running: the late connection is closed again.
        var late: FakeIsoDep? = null
        assertTrue(scan { controller -> FakeTag("eid", object : FakeIsoDep() {
            override fun connect() { controller.cancel(); super.connect() }
        }.also { late = it }) } is CardError.Cancelled)
        assertTrue(late!!.closed)

        // Connect fails because the session was cancelled: a cancellation, not a lost card.
        assertTrue(scan { controller -> FakeTag("eid", object : FakeIsoDep() {
            override fun connect() { controller.cancel(); throw IOException("closed") }
        }) } is CardError.Cancelled)
    }

    @Test fun cancelDuringATransceiveIsACancellation() {
        controller.resumed(activity)
        radio.cardOnEnable = FakeTag("eid", FakeIsoDep { controller.cancel(); throw IOException("closed") })
        val session = controller.open()
        try { session.transmit(byteArrayOf(0, 0xB0.toByte(), 0, 0, 2)); fail("cancelled") } catch (_: CardError.Cancelled) {}
        // A tag reported after the session ended is ignored.
        session.route.deliver(FakeTag("late", FakeIsoDep()))
        assertNull(controller.phase.value)
    }

    @Test fun readerModeActivationQueuedBehindACancelIsDropped() {
        val slow = NfcSigningController(radio, context, scanTimeoutMs = 60_000)
        slow.resumed(activity)
        val outcome = AtomicReference<Throwable?>()
        val worker = Thread { try { slow.open() } catch (error: Throwable) { outcome.set(error) } }
        worker.start()
        // The activation is posted to the main thread; cancel before it runs.
        while (slow.phase.value == null) Thread.sleep(1)
        slow.cancel()
        worker.join(60_000)
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(outcome.get() is CardError.Cancelled)
        assertTrue(radio.calls.isEmpty())
        assertFalse(slow.readerModeActive)
    }
}
