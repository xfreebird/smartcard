package md.moldsign.app.nfc

import android.app.Activity
import android.content.Context
import android.nfc.NfcAdapter
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import md.moldsign.core.*
import java.lang.ref.WeakReference
import java.util.concurrent.atomic.AtomicBoolean

/**
 * One foreground reader-mode session, one tag, one authentication attempt. Never reconnects.
 *
 * Reader mode itself is owned by [NfcReaderModeGate]: after a session has seen a card it stays enabled,
 * absorbing the card, until the activity pauses. Releasing it while the eID is still on the phone would
 * hand the card to the system dispatcher ("No supported app for this NFC tag").
 */
class NfcSigningController internal constructor(
    private val radio: NfcRadio,
    private val diagnosticsContext: Context,
    private val scanTimeoutMs: Long = SCAN_TIMEOUT_MS,
) {
    constructor(context: Context) : this(AndroidNfcRadio(NfcAdapter.getDefaultAdapter(context)), context.applicationContext)

    enum class Phase { Waiting, Reading, Signing }
    private val gate = NfcReaderModeGate(radio)
    private var host = WeakReference<Activity>(null)
    private var active: Session? = null
    private val state = MutableStateFlow<Phase?>(null)
    val phase = state.asStateFlow()
    val progress = MutableStateFlow(SigningStep.Idle)
    val available: Boolean get() = radio.available
    val enabled: Boolean get() = radio.enabled

    /** Reader mode is on: waiting for a card, or holding one after a session. */
    internal val readerModeActive: Boolean get() = gate.active

    @Synchronized fun resumed(activity: Activity) { host = WeakReference(activity) }
    @Synchronized fun paused(activity: Activity) {
        if (host.get() === activity) { cancel(); host.clear() }
        gate.paused(activity)
    }
    @Synchronized fun cancel() { active?.finish("cancelled") }

    /** Worker thread only. The same IsoDep connection is returned to the document signer. */
    fun open(): Session {
        val session: Session
        synchronized(this) {
            check(active == null) { "NFC session already active" }
            val activity = host.get() ?: throw CardError.Cancelled()
            if (!enabled) throw NfcUnavailable()
            session = Session(activity)
            active = session
            state.value = Phase.Waiting
            progress.value = SigningStep.Connecting
            activity.runOnUiThread {
                synchronized(this) {
                    if (active !== session || session.closed.get()) return@runOnUiThread
                    try { gate.open(activity, session.route) } catch (error: Exception) { session.failure(error) }
                }
            }
        }
        try { session.connect(); return session }
        catch (error: Throwable) { session.failure(error); throw error }
    }

    inner class Session internal constructor(private val activity: Activity) : ApduTransport {
        internal val closed = AtomicBoolean(false)
        private val tag = CompletableDeferred<NfcTagHandle>()
        private var iso: IsoDepLink? = null
        private val report = NfcDiagnostics(diagnosticsContext)
        override val readerName = "NFC"

        /** Reader-mode callback; the first card wins and late callbacks cannot reactivate a closed session. */
        internal val route = NfcReaderModeGate.Route<NfcTagHandle> { if (!closed.get()) tag.complete(it) }
        internal fun connect() {
            val value = runBlocking { withTimeoutOrNull(scanTimeoutMs) { tag.await() } } ?: throw NfcScanTimeout()
            val connection = value.isoDep() ?: throw NfcUnsupportedCard()
            synchronized(this@NfcSigningController) {
                if (closed.get()) throw CardError.Cancelled()
                iso = connection
            }
            try { connection.connect() }
            catch (_: java.io.IOException) { if (closed.get()) throw CardError.Cancelled() else throw NfcConnectionLost() }
            if (closed.get()) { connection.close(); throw CardError.Cancelled() }
            connection.timeout = TRANSCEIVE_TIMEOUT_MS
            report.event("connected", value = connection.maxTransceiveLength)
            state.value = Phase.Reading
        }
        override fun transmit(apdu: ByteArray): ByteArray {
            if (closed.get()) throw CardError.Cancelled()
            val connection = iso ?: throw CardError.NoCard()
            if (apdu.size > connection.maxTransceiveLength) throw CardError.Protocol("NFC command too large")
            return try {
                connection.transceive(apdu).also { response ->
                    report.command(apdu.getOrNull(1)?.toInt()?.and(255) ?: 0, response)
                }
            } catch (error: java.io.IOException) {
                if (closed.get()) throw CardError.Cancelled()
                report.event("connection_lost")
                throw NfcConnectionLost()
            }
        }
        fun step(value: SigningStep) { progress.value = value; report.event(value.name) }
        fun identified() { report.event("identity_bound"); state.value = Phase.Signing }
        fun cardSigned() { finish("card_signature_received") }
        fun documentSaved() { report.event("document_saved"); report.finish("document_saved") }
        fun failure(error: Throwable) {
            report.event("failure", category = error.javaClass.simpleName, value = (error as? CardError.UnexpectedStatus)?.sw)
            val outcome = if (error is CardError.Cancelled) "cancelled" else "failed"
            finish(outcome)
            // The core closes its transport before propagating an error. Preserve the final cause
            // even when RF cleanup already ran, or when timestamp/storage failed after card release.
            report.finish(outcome)
        }
        internal fun finish(outcome: String) {
            if (!closed.compareAndSet(false, true)) return
            tag.completeExceptionally(CardError.Cancelled())
            runCatching { iso?.close() }
            synchronized(this@NfcSigningController) {
                if (active === this) { active = null; state.value = null }
            }
            // Every outcome (signature, failure, cancel, timeout) goes through the gate: it keeps reader mode
            // while a seen card may still be in the field, and never releases a later scan's reader mode.
            activity.runOnUiThread {
                synchronized(this@NfcSigningController) {
                    if (gate.finished(route)) report.event("reader_mode_held")
                }
            }
            report.finish(outcome)
        }
        override fun close() { finish("closed") }
    }

    private companion object {
        const val SCAN_TIMEOUT_MS = 60_000L
        const val TRANSCEIVE_TIMEOUT_MS = 8_000
    }
}

class NfcUnavailable : Exception()
class NfcScanTimeout : Exception()
class NfcUnsupportedCard : Exception()
class NfcConnectionLost : Exception()
