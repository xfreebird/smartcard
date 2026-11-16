package md.moldsign.app.nfc

import android.app.Activity
import android.content.Context
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.IsoDep
import android.os.Bundle
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import md.moldsign.core.*
import java.lang.ref.WeakReference
import java.util.concurrent.atomic.AtomicBoolean

/** One foreground reader-mode session, one tag, one authentication attempt. Never reconnects. */
class NfcSigningController(context: Context) {
    enum class Phase { Waiting, Reading, Signing }
    private val adapter = NfcAdapter.getDefaultAdapter(context)
    private val diagnosticsContext = context.applicationContext
    private var host = WeakReference<Activity>(null)
    private var active: Session? = null
    private val state = MutableStateFlow<Phase?>(null)
    val phase = state.asStateFlow()
    val progress = MutableStateFlow(SigningStep.Idle)
    val available: Boolean get() = adapter != null
    val enabled: Boolean get() = adapter?.isEnabled == true

    @Synchronized fun resumed(activity: Activity) { host = WeakReference(activity) }
    @Synchronized fun paused(activity: Activity) {
        if (host.get() === activity) { cancel(); host.clear() }
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
                    try {
                        adapter!!.enableReaderMode(activity, session::discovered,
                            NfcAdapter.FLAG_READER_NFC_A or NfcAdapter.FLAG_READER_NFC_B or
                                NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK or NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS,
                            Bundle().apply { putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, 250) })
                    } catch (error: Exception) { session.failure(error) }
                }
            }
        }
        try { session.connect(); return session }
        catch (error: Throwable) { session.failure(error); throw error }
    }

    inner class Session internal constructor(private val activity: Activity) : ApduTransport {
        internal val closed = AtomicBoolean(false)
        private val tag = CompletableDeferred<Tag>()
        private var iso: IsoDep? = null
        private val report = NfcDiagnostics(diagnosticsContext)
        override val readerName = "NFC"

        internal fun discovered(value: Tag) { if (!closed.get()) tag.complete(value) }
        internal fun connect() {
            val value = runBlocking { withTimeoutOrNull(60_000) { tag.await() } } ?: throw NfcScanTimeout()
            val connection = IsoDep.get(value) ?: throw NfcUnsupportedCard()
            synchronized(this@NfcSigningController) {
                if (closed.get()) throw CardError.Cancelled()
                iso = connection
            }
            try { connection.connect() }
            catch (_: java.io.IOException) { if (closed.get()) throw CardError.Cancelled() else throw NfcConnectionLost() }
            if (closed.get()) { connection.close(); throw CardError.Cancelled() }
            connection.timeout = 8_000
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
            activity.runOnUiThread {
                synchronized(this@NfcSigningController) {
                    // A later explicit scan must not be disabled by this session's queued cleanup.
                    if (active == null) runCatching { adapter?.disableReaderMode(activity) }
                }
            }
            report.finish(outcome)
        }
        override fun close() { finish("closed") }
    }
}

class NfcUnavailable : Exception()
class NfcScanTimeout : Exception()
class NfcUnsupportedCard : Exception()
class NfcConnectionLost : Exception()
