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
        private var closed = false
        private var submitted: ConsentResult? = null
        private var delivered: ConsentResult? = null

        @Synchronized fun answer(value: ConsentResult) {
            if (closed || !result.complete(value)) {
                if (value is ConsentResult.Pin && value.pin !== (submitted as? ConsentResult.Pin)?.pin &&
                    value.pin !== (delivered as? ConsentResult.Pin)?.pin) value.pin.fill('\u0000')
            } else submitted = value
        }

        @Synchronized internal fun finish(consumed: ConsentResult) {
            closed = true
            val unused = submitted
            if (unused is ConsentResult.Pin && unused !== consumed) unused.pin.fill('\u0000')
            delivered = consumed
            submitted = null
            result.cancel()
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
        val prompt = PendingConsent(request, deferred)
        if (!_pending.compareAndSet(null, prompt)) {
            deferred.cancel()
            return ConsentResult.Cancelled
        }
        var answer: ConsentResult = ConsentResult.Cancelled
        try {
            answer = runBlocking {
                if (timeoutMs == null) deferred.await() else withTimeoutOrNull(timeoutMs) { deferred.await() } ?: ConsentResult.Cancelled
            }
            return answer
        } finally {
            prompt.finish(answer)
            _pending.compareAndSet(prompt, null)
        }
    }

    fun cancelPending() { _pending.value?.answer(ConsentResult.Cancelled) }

    val consent = Consent { request -> obtain(request) }
}
