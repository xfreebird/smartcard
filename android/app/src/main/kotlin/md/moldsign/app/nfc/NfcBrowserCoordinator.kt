package md.moldsign.app.nfc

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import md.moldsign.core.*

/** Public browser identity survives RF removal. Every request opens a fresh, bound NFC session. */
class NfcBrowserCoordinator(private val controller: NfcSigningController, context: android.content.Context) {
    private val identity = MutableStateFlow<CertificateSummary?>(null)
    val certificate = identity.asStateFlow()
    private val preferences = context.getSharedPreferences("browser_authentication", android.content.Context.MODE_PRIVATE)
    private val method = MutableStateFlow(controller.available && preferences.getBoolean("nfc", true))
    val enabled = method.asStateFlow()
    fun setEnabled(nfc: Boolean) {
        method.value = nfc && controller.available
        preferences.edit().putBoolean("nfc", method.value).apply()
    }
    fun seed(certificate: CertificateSummary?) { if (identity.value == null) identity.value = certificate }

    fun select(certificate: CertificateSummary?) { identity.value = certificate; setEnabled(true) }
    fun cards(): List<BridgeCard> = if (enabled.value && controller.available)
        identity.value?.let { listOf(BridgeCard("nfc:${it.sha1Hex}", it)) } ?: emptyList() else emptyList()

    fun identify() {
        controller.open().use { session ->
            try {
                val certificate = ContactlessCertificateReader.readIdentity(session, null)
                select(certificate)
            }
            catch (error: Throwable) { session.failure(error); throw error }
        }
    }

    fun sign(card: BridgeCard, request: ConsentRequest, consent: Consent,
             fallback: SigningService, operation: (SigningService, Consent) -> SignResult): SignResult {
        if (!card.readerId.startsWith("nfc:")) {
            if (enabled.value) throw CardError.Cancelled()
            return operation(fallback, consent)
        }
        if (!enabled.value || identity.value?.sha1Hex != card.certificate.sha1Hex) throw CardError.Cancelled()
        val answer = consent.obtain(request)
        val pin = (answer as? ConsentResult.Pin)?.pin ?: throw CardError.Cancelled()
        try {
            if (!enabled.value) throw CardError.Cancelled()
            controller.open().use { session ->
                try {
                    val summary = ContactlessCertificateReader.readIdentity(session, card.der)
                    session.identified()
                    val service = CardSigningService(TransportProvider { session },
                        MutableStateFlow(ReaderState.CardPresent("NFC")), chainDer = ChainCerts.chain,
                        onCardSignature = session::cardSigned, onProgress = session::step)
                    val authorized = Consent { live ->
                        if (live.certificate.der?.contentEquals(card.der) != true)
                            throw CardError.CardChanged(summary.sha1Hex, live.certificate.sha1Hex)
                        ConsentResult.Pin(pin.copyOf())
                    }
                    return operation(service, authorized)
                } catch (error: Throwable) { session.failure(error); throw error }
            }
        } finally { pin.fill('\u0000') }
    }
}
