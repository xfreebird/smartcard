package md.moldsign.app

import android.app.Application
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import md.moldsign.app.pin.PinVault
import md.moldsign.core.CardSigningService
import md.moldsign.core.CertificateSummary
import md.moldsign.core.ReaderSlot
import md.moldsign.core.SigningService
import md.moldsign.core.StatusLight
import md.moldsign.core.WalletCard
import md.moldsign.core.WalletState
import md.moldsign.transport.usb.UsbReaderMonitor

class MoldSignApp : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
        container.start()
    }
}

/** What the status light shows (docs/10 §0.1): the light plus the wallet it was computed from (for its text). */
data class AppStatus(val light: StatusLight, val wallet: WalletState, val busy: Boolean)

/** Manual DI: one instance of every app service (docs/09 §1 "App services"). */
class AppContainer(val app: Application) {
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val readerMonitor = UsbReaderMonitor(app, scope)
    val consentBroker = ConsentBroker()
    val pinVault = PinVault(app)
    val activity = ActivityLog(app, scope)

    /** Never log keys, PINs or SM payloads here (F-06 / SEC-04): CosmoXCard only emits step names. */
    val signingService: SigningService = CardSigningService(
        transports = readerMonitor.transportProvider,
        readerState = readerMonitor.state,
        log = { Log.d(TAG, it) },
    )

    private val _wallet = MutableStateFlow(WalletState())

    /** Readers, inserted cards (one per reader, with a generation) and the card used for signing (docs/09 §3.1b). */
    val wallet: StateFlow<WalletState> = _wallet.asStateFlow()

    private val _busy = MutableStateFlow(false)

    /** A signature (later: a bridge request, AND-04) is running: the blue light. */
    val busy: StateFlow<Boolean> = _busy.asStateFlow()

    val status: StateFlow<AppStatus> = combine(_wallet, _busy) { w, b -> AppStatus(w.light(b), w, b) }
        .stateIn(scope, SharingStarted.Eagerly, AppStatus(StatusLight.Idle, WalletState(), busy = false))

    /** PIN-less certificate read of one card. The debug demo mode swaps it for fake cards. */
    @Volatile private var certificateSource: (WalletCard) -> CertificateSummary = { signingService.certificate(it.readerId) }

    @Volatile private var followMonitor = true

    fun start() {
        activity.prune()
        readerMonitor.start()
        scope.launch { readerMonitor.readers.collect { if (followMonitor) apply(it) } }
    }

    /**
     * Reconciles the wallet with the monitor (Apple `AppModel.apply`): a card whose generation is unchanged keeps
     * its certificate; a new card or generation is read once, PIN-less, so the UI greets the holder (docs/09 §3.7).
     * Never retried in a loop (6985 trap, R-07): only a new generation or "Recitește cardul" reads again.
     */
    private fun apply(snapshot: List<ReaderSlot>) {
        var toRead = emptyList<WalletCard>()
        _wallet.update { w -> w.reconcile(snapshot).also { toRead = it.toRead }.state }
        toRead.forEach(::readCertificate)
    }

    private fun readCertificate(card: WalletCard) = scope.launch(Dispatchers.IO) {
        val result = runCatching { certificateSource(card) }
        result.exceptionOrNull()?.let { Log.w(TAG, "certificate read failed: ${it.javaClass.simpleName}") }
        // Ignored by WalletState when the card was removed or replaced meanwhile (generation check).
        _wallet.update { w -> result.fold({ w.withCertificate(card, it) }, { w.withProblem(card, it) }) }
    }

    /** "Recitește cardul": forget what is known about the inserted cards and read them again. */
    fun rereadCards() {
        var toRead = emptyList<WalletCard>()
        _wallet.update { w -> w.forgetCertificates().also { toRead = it.toRead }.state }
        toRead.forEach(::readCertificate)
    }

    fun selectCard(readerId: String) {
        _wallet.update { it.select(readerId) }
    }

    /** Runs a card job with the blue status light on. */
    suspend fun <T> whileBusy(block: suspend () -> T): T {
        _busy.value = true
        try {
            return block()
        } finally {
            _busy.value = false
        }
    }

    /**
     * Debug demo mode only (`src/debug/.../DemoMode.kt`; release builds ship a no-op): stops following the USB
     * monitor and shows [state]; "Recitește cardul" then reads through [source].
     */
    internal fun showDemo(state: WalletState, source: (WalletCard) -> CertificateSummary) {
        followMonitor = false
        certificateSource = source
        _wallet.value = state
    }

    private companion object {
        const val TAG = "MoldSign"
    }
}
