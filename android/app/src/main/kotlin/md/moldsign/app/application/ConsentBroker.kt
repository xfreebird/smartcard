package md.moldsign.app.application

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import md.moldsign.core.Consent
import md.moldsign.core.ConsentRequest
import md.moldsign.core.ConsentResult

/**
 * Bridges the synchronous core [Consent] callback (called on the signing thread) to Compose:
 * the request is published in [pending], the PIN sheet answers through [PendingConsent.answer].
 *
 * Bridge requests arrive while the app is in the background: `BridgeService` posts a heads-up notification that opens
 * the sheet, and asks with a timeout so an unanswered request cannot hold the card forever (AND-05).
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

    /**
     * Blocks the calling (signing) thread until the UI answers, or [timeoutMs] passes (then [ConsentResult.Cancelled]).
     * Never call on the main thread.
     */
    fun obtain(request: ConsentRequest, timeoutMs: Long? = null): ConsentResult {
        val deferred = CompletableDeferred<ConsentResult>()
        _pending.value = PendingConsent(request, deferred)
        try {
            return runBlocking {
                if (timeoutMs == null) deferred.await() else withTimeoutOrNull(timeoutMs) { deferred.await() } ?: ConsentResult.Cancelled
            }
        } finally {
            _pending.value = null
        }
    }

    val consent = Consent { request -> obtain(request) }
}
