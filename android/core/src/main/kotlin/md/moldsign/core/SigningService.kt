package md.moldsign.core

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/** Opens a fresh transport per card operation (CCID: claim + power-on reset). */
fun interface TransportProvider {
    /** Throws [CardError.NoReader] / [CardError.NoCard]. */
    fun open(): ApduTransport
}

/**
 * App-facing facade (docs/09 §3.4). Synchronous: call it off the main thread.
 * Every card operation goes through one process-wide lock (interleaved SM sessions desync the SSC).
 */
interface SigningService {
    val readerState: StateFlow<ReaderState>
    val progress: StateFlow<SigningStep>

    /** Holder certificate summary: mutual auth + EF 0001, no PIN. */
    fun certificate(): CertificateSummary

    fun signPdf(input: Document, consent: Consent, requester: String? = null): SignResult

    fun signXades(
        files: List<Document>,
        level: XadesLevel,
        packaging: XadesPackaging,
        consent: Consent,
        requester: String? = null,
    ): SignResult

    /** Raw card signature over a DigestInfo (bridge `/sign/data` building block, CLI `sign-hex`). */
    fun signDigestInfo(digestInfo: ByteArray, documentName: String, consent: Consent, requester: String? = null): RawSignature

    fun verify(file: Document, detachedDocuments: List<Document> = emptyList()): List<ValidationReport>
}

class CardSigningService(
    private val transports: TransportProvider,
    override val readerState: StateFlow<ReaderState>,
    private val pades: PadesSigner = UnportedPadesSigner(),
    private val xades: XadesSigner = UnportedXadesSigner(),
    private val validator: Validator = UnportedValidator(),
    /** Issuer chain (MDQSign CA, mdtrustca) as DER. TODO(AND-01): port ChainCerts.swift. */
    private val chainDer: List<ByteArray> = emptyList(),
    private val log: (String) -> Unit = {},
) : SigningService {
    private val progressFlow = MutableStateFlow(SigningStep.Idle)
    override val progress: StateFlow<SigningStep> = progressFlow.asStateFlow()

    override fun certificate(): CertificateSummary = withCard { card ->
        card.selectMF()
        card.selectGenericADF()
        step(SigningStep.ReadingCertificate)
        CertificateSummary.parse(card.readCertificate())
    }

    override fun signPdf(input: Document, consent: Consent, requester: String?): SignResult = withCard { card ->
        val certDer = readCertificate(card)
        val summary = CertificateSummary.parse(certDer)
        val request = ConsentRequest(requester, listOf(input.name), FORMAT_PADES_T, summary)
        val signed = pades.sign(input.bytes, certDer, chainDer, cardSigner(card, request, consent))
        step(SigningStep.Done)
        SignResult(signed, summary, FORMAT_PADES_T)
    }

    override fun signXades(
        files: List<Document>,
        level: XadesLevel,
        packaging: XadesPackaging,
        consent: Consent,
        requester: String?,
    ): SignResult = withCard { card ->
        val certDer = readCertificate(card)
        val summary = CertificateSummary.parse(certDer)
        val format = "XAdES-${level.name}"
        val request = ConsentRequest(requester, files.map { it.name }, format, summary)
        val signed = xades.sign(files, level, packaging, certDer, chainDer, cardSigner(card, request, consent))
        step(SigningStep.Done)
        SignResult(signed, summary, format)
    }

    override fun signDigestInfo(digestInfo: ByteArray, documentName: String, consent: Consent, requester: String?): RawSignature =
        withCard { card ->
            val certDer = readCertificate(card)
            val request = ConsentRequest(requester, listOf(documentName), "PKCS#1", CertificateSummary.parse(certDer))
            val sig = cardSigner(card, request, consent).sign(digestInfo)
            step(SigningStep.Done)
            RawSignature(sig, certDer)
        }

    override fun verify(file: Document, detachedDocuments: List<Document>): List<ValidationReport> {
        val isPdf = file.bytes.size >= 5 && String(file.bytes, 0, 5, Charsets.ISO_8859_1) == "%PDF-"
        return if (isPdf) validator.verifyPdf(file.bytes) else validator.verifyXades(file.bytes, detachedDocuments)
    }

    // ------------------------------------------------------------------ card session

    private fun <T> withCard(block: (CosmoXCard) -> T): T = CARD_LOCK.withLock {
        step(SigningStep.Connecting)
        try {
            transports.open().use { transport ->
                val card = CosmoXCard(transport, log)
                step(SigningStep.Authenticating)
                card.authenticate()
                block(card)
            }
        } finally {
            if (progressFlow.value != SigningStep.Done) step(SigningStep.Idle)
        }
    }

    /** Swift `signPDF` order: SELECT MF → ADF → readCertificate (which re-selects MF/ADF/EF). */
    private fun readCertificate(card: CosmoXCard): ByteArray {
        card.selectMF()
        card.selectGenericADF()
        step(SigningStep.ReadingCertificate)
        return card.readCertificate()
    }

    /** The PIN is requested lazily, only once the document hash is ready; never retried (R-07). */
    private fun cardSigner(card: CosmoXCard, request: ConsentRequest, consent: Consent) = RawSigner { digestInfo ->
        val pin = when (val answer = consent.obtain(request)) {
            is ConsentResult.Pin -> answer.pin
            ConsentResult.Cancelled -> throw CardError.Cancelled()
        }
        try {
            step(SigningStep.VerifyingPin)
            card.selectGenericADF()
            card.verifyPin(pin)
            step(SigningStep.Signing)
            card.sign(digestInfo)
        } finally {
            pin.fill('\u0000')
        }
    }

    private fun step(s: SigningStep) {
        progressFlow.value = s
    }

    companion object {
        const val FORMAT_PADES_T = "PAdES-T"

        /** Process-wide: UI and bridge requests queue behind it (MAC-11 equivalent). */
        private val CARD_LOCK = ReentrantLock()
    }
}
