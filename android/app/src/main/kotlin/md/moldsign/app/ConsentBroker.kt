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
