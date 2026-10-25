package md.moldsign.app

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.runBlocking
import md.moldsign.core.Consent
import md.moldsign.core.ConsentRequest
import md.moldsign.core.ConsentResult

/**
 * Bridges the synchronous core [Consent] callback (called on the signing thread) to Compose:
 * the request is published in [pending], the PIN sheet answers through [PendingConsent.answer].
 *
 * TODO(AND-05): bridge requests arrive while the app may be in the background; post a heads-up
 *  notification ("Semnează contract.pdf pentru msign.gov.md?") that opens the consent sheet.
 * TODO(AND-06): when PinVault holds a PIN for the certificate, show BiometricPrompt instead of the sheet.
 */
class ConsentBroker {
    class PendingConsent(val request: ConsentRequest, private val result: CompletableDeferred<ConsentResult>) {
        fun answer(value: ConsentResult) {
            result.complete(value)
        }
    }

    private val _pending = MutableStateFlow<PendingConsent?>(null)
    val pending: StateFlow<PendingConsent?> = _pending.asStateFlow()

    /** Blocks the calling (signing) thread until the UI answers. Never call on the main thread. */
    val consent = Consent { request ->
        val deferred = CompletableDeferred<ConsentResult>()
        _pending.value = PendingConsent(request, deferred)
        try {
            runBlocking { deferred.await() }
        } finally {
            _pending.value = null
        }
    }
}

/**
 * One PIN entry for a batch ("Semnează 3 documente", like the Apple `signAll`): the first request goes to [inner],
 * later ones get a copy of the same PIN (the core wipes each copy after VERIFY). [close] wipes the kept copy.
 * A wrong PIN stops the batch at the first document (CardError.WrongPin is never retried, R-07).
 */
class BatchConsent(private val inner: Consent) : Consent, AutoCloseable {
    private var pin: CharArray? = null

    @Synchronized
    override fun obtain(request: ConsentRequest): ConsentResult {
        pin?.let { return ConsentResult.Pin(it.copyOf()) }
        val answer = inner.obtain(request)
        if (answer is ConsentResult.Pin) pin = answer.pin.copyOf()
        return answer
    }

    @Synchronized
    override fun close() {
        pin?.fill('\u0000')
        pin = null
    }
}
