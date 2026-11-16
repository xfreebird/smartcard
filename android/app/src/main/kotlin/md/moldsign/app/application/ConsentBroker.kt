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
import md.moldsign.core.CertificateSummary

data class PinRequest(val requester: String?, val documentNames: List<String>, val format: String,
    val certificate: CertificateSummary?, val attemptsLeft: Int? = null)
class PinToSave(val certificate: CertificateSummary, val pin: CharArray)

/**
 * Bridges the synchronous core [Consent] callback (called on the signing thread) to Compose:
 * the request is published in [pending], the PIN sheet answers through [PendingConsent.answer].
 *
 * Bridge requests arrive while the app is in the background: `BridgeService` posts a heads-up notification that opens
 * the sheet, and asks with a timeout so an unanswered request cannot hold the card forever (AND-05).
 * The same prompt offers biometric retrieval for a selected saved identity on either transport.
 */
class ConsentBroker {
    class PendingConsent(val request: PinRequest, private val result: CompletableDeferred<ConsentResult>,
        private val remember: (CharArray, CertificateSummary?) -> Unit = { _, _ -> }) {
        private var closed = false
        private var submitted: ConsentResult? = null
        private var delivered: ConsentResult? = null

        @Synchronized fun answer(value: ConsentResult, rememberPin: Boolean = false) {
            if (closed || result.isCompleted) {
                if (value is ConsentResult.Pin && value.pin !== (submitted as? ConsentResult.Pin)?.pin &&
                    value.pin !== (delivered as? ConsentResult.Pin)?.pin) value.pin.fill('\u0000')
            } else {
                submitted = value
                if (rememberPin && value is ConsentResult.Pin) remember(value.pin, request.certificate)
                result.complete(value)
            }
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
    private var rememberedPin: CharArray? = null
    private var rememberedIdentity: String? = null
    @Synchronized private fun remember(pin: CharArray, certificate: CertificateSummary?) {
        discardRemembered()
        rememberedPin = pin.copyOf()
        rememberedIdentity = certificate?.sha1Hex
    }
    @Synchronized fun discardRemembered() { rememberedPin?.fill('\u0000'); rememberedPin = null; rememberedIdentity = null }
    @Synchronized fun afterSuccess(certificate: CertificateSummary): PinToSave? {
        val pin = rememberedPin ?: return null
        if (rememberedIdentity != null && rememberedIdentity != certificate.sha1Hex) { discardRemembered(); return null }
        rememberedPin = null; rememberedIdentity = null
        return PinToSave(certificate, pin)
    }

    /**
     * Blocks the calling (signing) thread until the UI answers, or [timeoutMs] passes (then [ConsentResult.Cancelled]).
     * Never call on the main thread.
     */
    fun obtain(request: ConsentRequest, timeoutMs: Long? = null): ConsentResult {
        return obtainPin(PinRequest(request.requester, request.documentNames, request.format, request.certificate, request.attemptsLeft), timeoutMs)
    }

    fun obtainPin(request: PinRequest, timeoutMs: Long? = null): ConsentResult {
        val deferred = CompletableDeferred<ConsentResult>()
        val prompt = PendingConsent(request, deferred, ::remember)
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
