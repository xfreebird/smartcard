package md.moldsign.app.nfc

import md.moldsign.app.application.*
import md.moldsign.core.*
import kotlinx.coroutines.flow.MutableStateFlow

/** PIN first; public identity and the guarded signature use one uninterrupted ISO-DEP connection. */
class NfcSignDocuments(private val controller: NfcSigningController, private val broker: ConsentBroker,
    private val data: DocumentDataProvider, private val outputs: DocumentOutputStore) {
    fun execute(items: List<SignItem>, selected: CertificateSummary?,
        identified: (CertificateSummary) -> Unit, emit: (SignDocuments.Event) -> Unit) {
        // Read inputs before collecting a PIN or enabling the antenna.
        val inputs = items.map { data.document(it.doc) }
        val answer = broker.obtainPin(PinRequest(null, items.map { it.doc.name },
            items.map { it.format.label }.distinct().joinToString(" · "), selected))
        val pin = (answer as? ConsentResult.Pin)?.pin ?: throw CardError.Cancelled()
        var expected = selected?.der?.copyOf()
        if (selected != null && expected == null) { pin.fill('\u0000'); throw CardError.Protocol("Missing selected certificate") }
        try {
            items.zip(inputs).forEach { (item, input) ->
                emit(SignDocuments.Event.Started(item))
                try {
                    controller.open().use { session ->
                        try {
                            val summary = ContactlessCertificateReader.readIdentity(session, expected)
                            val certificate = requireNotNull(summary.der)
                            expected = certificate.copyOf()
                            identified(summary)
                            session.identified()
                            val service = CardSigningService(TransportProvider { session },
                                MutableStateFlow(ReaderState.CardPresent("NFC")), chainDer = ChainCerts.chain,
                                onCardSignature = session::cardSigned,
                                onProgress = session::step)
                            val consent = Consent { request ->
                                if (!request.certificate.der!!.contentEquals(certificate)) throw CardError.CardChanged(summary.sha1Hex, request.certificate.sha1Hex)
                                ConsentResult.Pin(pin.copyOf())
                            }
                            val result = service.sign(input, item.format, consent,
                                expectedCertificateSha1 = summary.sha1Hex, placement = item.stamp)
                            val name = SignFormat.outputName(item.doc.name, item.format)
                            val uri = outputs.save(name, if (item.format.xadesLevel == null) "application/pdf" else "application/xml", result.output)
                            session.documentSaved()
                            emit(SignDocuments.Event.Saved(item, name, uri, result.certificate))
                        } catch (error: Throwable) { session.failure(error); throw error }
                    }
                } catch (error: Exception) {
                    if (error !is CardError.Cancelled && error !is kotlinx.coroutines.CancellationException)
                        emit(SignDocuments.Event.Failed(item, error))
                    throw error // No automatic authentication/PIN retry, including later batch documents.
                }
            }
        } finally { pin.fill('\u0000') }
    }
}
