package md.moldsign.app

import android.app.Application
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import md.moldsign.app.pin.PinVault
import md.moldsign.core.CardError
import md.moldsign.core.CardSigningService
import md.moldsign.core.CertificateSummary
import md.moldsign.core.ReaderState
import md.moldsign.core.SigningService
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

/** Manual DI: one instance of every app service (docs/09 §1 "App services"). */
class AppContainer(app: Application) {
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val readerMonitor = UsbReaderMonitor(app, scope)
    val consentBroker = ConsentBroker()
    val pinVault = PinVault(app)

    /** Never log keys, PINs or SM payloads here (F-06 / SEC-04): CosmoXCard only emits step names. */
    val signingService: SigningService = CardSigningService(
        transports = readerMonitor.transportProvider,
        readerState = readerMonitor.state,
        log = { Log.d("MoldSign", it) },
    )

    private val _certificate = MutableStateFlow<CertificateSummary?>(null)
    val certificate: StateFlow<CertificateSummary?> = _certificate.asStateFlow()

    private val _cardError = MutableStateFlow<Throwable?>(null)
    val cardError: StateFlow<Throwable?> = _cardError.asStateFlow()

    fun start() {
        readerMonitor.start()
        greetHolderOnInsert()
    }

    /**
     * docs/09 §3.7: on card insert, read the certificate without a PIN so the UI greets the holder.
     * Exactly one attempt per insertion: never loop on auth failures (6985 trap, R-07).
     */
    private fun greetHolderOnInsert() = scope.launch {
        var attemptedForThisCard = false
        readerMonitor.state.collect { s ->
            when (s) {
                is ReaderState.CardPresent -> if (!attemptedForThisCard) {
                    attemptedForThisCard = true
                    readCertificate()
                }
                is ReaderState.Empty, ReaderState.NoReader, is ReaderState.PermissionRequired -> {
                    attemptedForThisCard = false
                    _certificate.value = null
                    _cardError.value = null
                }
                else -> Unit
            }
        }
    }

    fun readCertificate() = scope.launch(Dispatchers.IO) {
        try {
            val summary = signingService.certificate()
            _certificate.value = summary
            _cardError.value = null
            readerMonitor.setHolder(summary.commonName)
        } catch (e: CardError) {
            Log.w("MoldSign", "certificate read failed: ${e.javaClass.simpleName}")
            _cardError.value = e
        } catch (e: Exception) {
            Log.w("MoldSign", "certificate read failed", e)
            _cardError.value = e
        }
    }
}
