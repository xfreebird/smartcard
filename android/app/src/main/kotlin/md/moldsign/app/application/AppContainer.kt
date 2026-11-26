package md.moldsign.app.application

import md.moldsign.app.R
import md.moldsign.app.infrastructure.ActivityLog
import md.moldsign.app.infrastructure.ProtectedFileStore
import md.moldsign.app.infrastructure.SignedFileStore
import md.moldsign.app.infrastructure.UsbReaderGateway
import md.moldsign.app.infrastructure.demo.DemoReaderGateway
import md.moldsign.app.infrastructure.demo.DemoSigningService
import kotlinx.coroutines.cancel

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
import md.moldsign.core.BridgeCard
import md.moldsign.core.CardSigningService
import md.moldsign.core.CertificateSummary
import md.moldsign.core.ChainCerts
import md.moldsign.core.MdTrustServices
import md.moldsign.core.PadesCmsSigner
import md.moldsign.core.ReaderSlot
import md.moldsign.core.SigningService
import md.moldsign.core.StatusLight
import md.moldsign.core.WalletCard
import md.moldsign.core.WalletState
import md.moldsign.core.XadesDocumentSigner
import java.util.concurrent.atomic.AtomicInteger

/** What the status light shows (docs/10 §0.1): the light plus the wallet it was computed from (for its text). */
data class AppStatus(val light: StatusLight, val wallet: WalletState, val busy: Boolean)

/** Manual DI: one instance of every app service (docs/09 §1 "App services"). */
class AppContainer(
    val app: Application,
    val userDemoMode: Boolean = false,
    signingFactory: ((ReaderGateway) -> SigningService)? = null,
    readerFactory: (Application, CoroutineScope) -> ReaderGateway = ::UsbReaderGateway,
    val previewData: PreviewDataProvider = md.moldsign.app.infrastructure.demo.DemoDataProvider(),
    demoSigningFactory: (() -> SigningService)? = null,
    nfcFactory: (Application) -> md.moldsign.app.nfc.NfcSigningController = { md.moldsign.app.nfc.NfcSigningController(it) },
) {
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val readerMonitor: ReaderGateway = if (userDemoMode) DemoReaderGateway() else readerFactory(app, scope)
    val consentBroker = ConsentBroker()
    val stampBroker = StampBroker(app)
    val pinVault = PinVault(app)
    val savedCardIdentities = md.moldsign.app.pin.SavedCardIdentities(app)
    val nfc = nfcFactory(app)
    val browserNfc = md.moldsign.app.nfc.NfcBrowserCoordinator(nfc, app)
    val activity = ActivityLog(app, scope, if (userDemoMode) "demo-activity" else "activity")
    val signedFiles = SignedFileStore(app)

    /**
     * Both modes execute the same batch policy; demo persistence accepts only provider-owned sample bytes. Demo
     * outputs stay in app-private storage: the DEMO files never join real signed documents in Downloads/eSemnBun.
     */
    fun signingWorkflow(data: DocumentDataProvider): SignDocuments = if (userDemoMode) {
        SignDocuments(signingService, previewData,
            DocumentOutputStore { name, _, _ -> ProtectedFileStore(app).save(name, previewData.outputBytes()) },
            outputName = { previewData.outputName(it.doc.name) })
    } else SignDocuments(signingService, data, signedFiles)

    private val trust = MdTrustServices()

    /** Never log keys, PINs or SM payloads here (F-06 / SEC-04): CosmoXCard only emits step names. */
    val signingService: SigningService = if (userDemoMode) demoSigningFactory?.invoke() ?: DemoSigningService() else signingFactory?.invoke(readerMonitor) ?: CardSigningService(
        transports = readerMonitor.transportProvider,
        readerState = readerMonitor.state,
        pades = PadesCmsSigner(trust),
        xades = XadesDocumentSigner(trust),
        chainDer = ChainCerts.chain,
        log = { Log.d(TAG, it) },
    )

    private val _wallet = MutableStateFlow(WalletState())

    /** Readers, inserted cards (one per reader, with a generation) and the card used for signing (docs/09 §3.1b). */
    val wallet: StateFlow<WalletState> = _wallet.asStateFlow()

    private val _busy = MutableStateFlow(false)
    private val busyJobs = AtomicInteger(0)

    /** A signature (from the app or a browser request) is running: the blue light. */
    val busy: StateFlow<Boolean> = _busy.asStateFlow()

    /** The activity is on screen: bridge requests then use the PIN sheet directly, without a heads-up notification. */
    @Volatile var inForeground = false

    val status: StateFlow<AppStatus> = combine(_wallet, _busy) { w, b -> AppStatus(w.light(b), w, b) }
        .stateIn(scope, SharingStarted.Eagerly, AppStatus(StatusLight.Idle, WalletState(), busy = false))

    /** PIN-less certificate read of one card. The debug demo mode swaps it for fake cards. */
    @Volatile private var certificateSource: (WalletCard) -> CertificateSummary = { signingService.certificate(it.readerId) }

    @Volatile private var followMonitor = true

    fun start() {
        activity.prune()
        // Copies of files shared to "Semnează" (AND-07) only live for one session.
        if (!userDemoMode) scope.launch(Dispatchers.IO) { java.io.File(app.cacheDir, SHARED_DOCUMENT_CACHE).deleteRecursively() }
        readerMonitor.start()
        scope.launch { readerMonitor.readers.collect { if (followMonitor) apply(it) } }
    }

    /**
     * Reconciles the wallet with the monitor (Apple `AppModel.apply`): a card whose generation is unchanged keeps
     * its certificate; a new card or generation is read once, PIN-less, so the UI greets the holder (docs/09 §3.7).
     * Never retried in a loop (6985 trap, R-07): only a new generation or "Recitește cardul" reads again.
     */
    private var pendingSnapshot: List<ReaderSlot>? = null
    private fun apply(snapshot: List<ReaderSlot>) {
        if (_busy.value) { pendingSnapshot = snapshot; return }
        var toRead = emptyList<WalletCard>()
        _wallet.update { w -> w.reconcile(snapshot).also { toRead = it.toRead }.state }
        toRead.forEach(::readCertificate)
    }

    private fun readCertificate(card: WalletCard) = scope.launch(Dispatchers.IO) {
        val result = runCatching { certificateSource(card) }
        result.exceptionOrNull()?.let { Log.w(TAG, "certificate read failed: ${it.javaClass.simpleName}: ${it.message}") }
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
        beginBusy()
        try {
            return block()
        } finally {
            endBusy()
        }
    }

    fun beginBusy() {
        busyJobs.incrementAndGet()
        _busy.value = true
    }

    fun endBusy() {
        _busy.value = busyJobs.decrementAndGet() > 0
        if (!_busy.value) pendingSnapshot?.let { pendingSnapshot = null; apply(it) }
    }

    /** The cards a browser may sign with: every ready card whose certificate DER is known (not the demo cards). */
    fun bridgeCards(): List<BridgeCard> = if (isDemo) emptyList() else if (browserNfc.enabled.value) browserNfc.cards() else _wallet.value.readyCards.mapNotNull { card ->
        card.certificate?.takeIf { it.der != null }?.let { BridgeCard(card.readerId, it) }
    }.distinctBy { it.certificate.sha1Hex }

    /**
     * Debug demo mode only (`src/debug/.../DemoMode.kt`; release builds ship a no-op): stops following the USB
     * monitor and shows [state]; "Recitește cardul" then reads through [source].
     */
    @Volatile var isDemo = userDemoMode
        private set

    internal fun showDemo(state: WalletState, source: (WalletCard) -> CertificateSummary) {
        isDemo = true
        readerMonitor.stop()
        followMonitor = false
        certificateSource = source
        _wallet.value = state
    }

    fun stop() {
        nfc.cancel()
        consentBroker.discardRemembered()
        consentBroker.cancelPending()
        stampBroker.cancelPending()
        readerMonitor.stop()
        followMonitor = false
        scope.cancel()
    }

    private companion object {
        const val TAG = "MoldSign"
    }
}
