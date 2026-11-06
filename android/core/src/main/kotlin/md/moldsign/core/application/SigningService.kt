package md.moldsign.core

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/** Opens a fresh transport per card operation (CCID: claim + power-on reset). */
fun interface TransportProvider {
    /**
     * Opens a session on [reader] (a `ReaderSlot.id`); `null` = the first reader holding a card.
     * Throws [CardError.NoReader] / [CardError.NoCard].
     */
    fun open(reader: String?): ApduTransport
}

/**
 * App-facing facade (docs/09 §3.4). Synchronous: call it off the main thread.
 * Every card operation goes through one process-wide lock (interleaved SM sessions desync the SSC).
 */
interface SigningService {
    val readerState: StateFlow<ReaderState>
    val progress: StateFlow<SigningStep>

    /** Holder certificate summary of the card in [reader] (`null` = first card): mutual auth + EF 0001, no PIN. */
    fun certificate(reader: String? = null): CertificateSummary

    /*
     * Signing calls take the card to use: [reader] routes the session (several cards can be connected,
     * docs/09 §3.1b) and `expectedCertificateSha1` is the card the user selected / the PIN belongs to. The card's
     * certificate is read and compared BEFORE the consent / PIN is asked for and before VERIFY; a different
     * card fails with CardError.CardChanged.
     */

    fun signPdf(
        input: Document,
        consent: Consent,
        requester: String? = null,
        reader: String? = null,
        expectedCertificateSha1: String? = null,
    ): SignResult

    fun signPdfVisible(input: Document, consent: Consent, placement: PdfStampPlacement,
        requester: String? = null, reader: String? = null, expectedCertificateSha1: String? = null): SignResult =
        throw CardError.Format("Visible signatures are not supported by this signer")

    fun signXades(
        files: List<Document>,
        level: XadesLevel,
        packaging: XadesPackaging,
        consent: Consent,
        requester: String? = null,
        reader: String? = null,
        expectedCertificateSha1: String? = null,
        digest: XadesDigest = XadesDigest.SHA256,
    ): SignResult

    /**
     * Signs [input] in the format the user picked: PAdES-T → [signPdf]; XAdES-BES/T/C → a detached [signXades] over the
     * file's bytes, PDFs included. PAdES on a non-PDF fails with [CardError.Format] before the card is touched.
     */
    fun sign(
        input: Document,
        format: SignFormat,
        consent: Consent,
        requester: String? = null,
        reader: String? = null,
        expectedCertificateSha1: String? = null,
        placement: PdfStampPlacement? = null,
    ): SignResult = when (val level = format.xadesLevel) {
        null -> {
            if (!input.isPdf()) throw CardError.Format("A PDF signature needs a PDF: ${input.name}")
            if (placement == null) signPdf(input, consent, requester, reader, expectedCertificateSha1)
            else signPdfVisible(input, consent, placement, requester, reader, expectedCertificateSha1)
        }
        else -> signXades(listOf(input), level, XadesPackaging.Detached, consent, requester, reader, expectedCertificateSha1)
    }

    /** Raw card signature over a DigestInfo (bridge `/sign/data` building block, CLI `sign-hex`). */
    fun signDigestInfo(
        digestInfo: ByteArray,
        documentName: String,
        consent: Consent,
        requester: String? = null,
        reader: String? = null,
        expectedCertificateSha1: String? = null,
    ): RawSignature

    fun verify(file: Document, detachedDocuments: List<Document> = emptyList()): List<ValidationReport>
}

class CardSigningService(
    private val transports: TransportProvider,
    override val readerState: StateFlow<ReaderState>,
    private val pades: PadesSigner = PadesCmsSigner(MdTrustServices()),
    private val xades: XadesSigner = XadesDocumentSigner(MdTrustServices()),
    private val validator: Validator = OfflineValidator(),
    /** Issuer chain (MDQSign CA, mdtrustca) as DER: [ChainCerts.chain]. */
    private val chainDer: List<ByteArray> = emptyList(),
    private val log: (String) -> Unit = {},
) : SigningService {
    private val progressFlow = MutableStateFlow(SigningStep.Idle)
    override val progress: StateFlow<SigningStep> = progressFlow.asStateFlow()

    override fun certificate(reader: String?): CertificateSummary = withCard(reader) { card ->
        card.selectMF()
        card.selectGenericADF()
        step(SigningStep.ReadingCertificate)
        CertificateSummary.parse(card.readCertificate())
    }

    override fun signPdf(
        input: Document,
        consent: Consent,
        requester: String?,
        reader: String?,
        expectedCertificateSha1: String?,
    ): SignResult = signPdfInternal(input, consent, requester, reader, expectedCertificateSha1, null)

    override fun signPdfVisible(input: Document, consent: Consent, placement: PdfStampPlacement,
        requester: String?, reader: String?, expectedCertificateSha1: String?): SignResult =
        signPdfInternal(input, consent, requester, reader, expectedCertificateSha1, placement)

    private fun signPdfInternal(input: Document, consent: Consent, requester: String?, reader: String?,
        expectedCertificateSha1: String?, placement: PdfStampPlacement?): SignResult = withCard(reader) { card ->
        val certDer = readCertificate(card, expectedCertificateSha1)
        val summary = CertificateSummary.parse(certDer)
        val request = ConsentRequest(requester, listOf(input.name), FORMAT_PADES_T, summary)
        val raw = cardSigner(card, request, consent)
        val signed = if (placement == null) pades.sign(input.bytes, certDer, chainDer, raw)
            else pades.signVisible(input.bytes, certDer, chainDer, raw, placement)
        step(SigningStep.Done)
        SignResult(signed, summary, FORMAT_PADES_T)
    }

    override fun signXades(
        files: List<Document>,
        level: XadesLevel,
        packaging: XadesPackaging,
        consent: Consent,
        requester: String?,
        reader: String?,
        expectedCertificateSha1: String?,
        digest: XadesDigest,
    ): SignResult = withCard(reader) { card ->
        val certDer = readCertificate(card, expectedCertificateSha1)
        val summary = CertificateSummary.parse(certDer)
        val format = "XAdES-${level.name}"
        val request = ConsentRequest(requester, files.map { it.name }, format, summary)
        val signed = xades.sign(files, level, packaging, certDer, chainDer, cardSigner(card, request, consent), digest)
        step(SigningStep.Done)
        SignResult(signed, summary, format)
    }

    override fun signDigestInfo(
        digestInfo: ByteArray,
        documentName: String,
        consent: Consent,
        requester: String?,
        reader: String?,
        expectedCertificateSha1: String?,
    ): RawSignature = withCard(reader) { card ->
        val certDer = readCertificate(card, expectedCertificateSha1)
        val request = ConsentRequest(requester, listOf(documentName), "PKCS#1", CertificateSummary.parse(certDer))
        val sig = cardSigner(card, request, consent).sign(digestInfo)
        step(SigningStep.Done)
        RawSignature(sig, certDer)
    }

    override fun verify(file: Document, detachedDocuments: List<Document>): List<ValidationReport> =
        if (file.isPdf()) validator.verifyPdf(file.bytes) else validator.verifyXades(file.bytes, detachedDocuments)

    // ------------------------------------------------------------------ card session

    private fun <T> withCard(reader: String?, block: (CosmoXCard) -> T): T = CARD_LOCK.withLock {
        step(SigningStep.Connecting)
        try {
            transports.open(reader).use { transport ->
                val card = CosmoXCard(transport, log)
                step(SigningStep.Authenticating)
                card.authenticate()
                block(card)
            }
        } finally {
            if (progressFlow.value != SigningStep.Done) step(SigningStep.Idle)
        }
    }

    /**
     * Swift `signPDF` order: SELECT MF → ADF → readCertificate (which re-selects MF/ADF/EF) → identity guard.
     * Runs before the consent / PIN request, so a swapped card fails here and never sees a PIN.
     */
    private fun readCertificate(card: CosmoXCard, expectedSha1: String?): ByteArray {
        card.selectMF()
        card.selectGenericADF()
        step(SigningStep.ReadingCertificate)
        return card.readCertificate().also { CosmoXCard.checkIdentity(it, expectedSha1) }
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
