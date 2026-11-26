package md.moldsign.app.testing

import android.net.Uri
import android.os.Looper
import kotlinx.coroutines.flow.MutableStateFlow
import md.moldsign.app.application.DocumentAccess
import md.moldsign.app.application.ReaderGateway
import md.moldsign.app.application.PickedDocument
import md.moldsign.core.*
import org.robolectric.Shadows.shadowOf
import java.util.Calendar
import java.util.TimeZone

/** A public-looking but fictional certificate summary (no DER: never valid for the bridge). */
fun testCertificate(name: String = "TEST HOLDER", sha1: String = "0123456789ABCDEF0123456789ABCDEF01234567", der: ByteArray? = null) =
    CertificateSummary(
        commonName = name, subjectDn = "CN=$name,C=MD", issuerDn = "CN=Test CA,C=MD", issuerCommonName = "Test CA",
        notBefore = date(2024), notAfter = date(2030), serialHex = sha1.take(16), sha1Hex = sha1,
        surname = name.substringBefore(' '), givenNames = name.substringAfter(' ', ""), der = der,
    )

private fun date(year: Int) = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { set(year, 0, 15, 0, 0, 0) }.time

/** USB readers without hardware: the test sets the slots it wants the wallet to see. */
class FakeReaderGateway(initial: List<ReaderSlot> = listOf(ReaderSlot("usb-1", "Test reader", ReaderSlot.State.Card, 1))) : ReaderGateway {
    override val readers = MutableStateFlow(initial)
    override val state = MutableStateFlow<ReaderState>(ReaderState.CardPresent("Test reader"))
    override val transportProvider = TransportProvider { throw CardError.NoReader() }
    val permissionRequests = mutableListOf<String?>()
    var started = false
    var rescans = 0
    override fun start() { started = true }
    override fun stop() { started = false }
    override fun rescan() { rescans++ }
    override fun requestPermission(readerId: String?) { permissionRequests += readerId }
}

/** Signs with fixed bytes and never asks for a PIN unless [askConsent] is set. */
class FakeSigningService(var certificate: CertificateSummary = testCertificate()) : SigningService {
    override val readerState = MutableStateFlow<ReaderState>(ReaderState.CardPresent("Test reader"))
    override val progress = MutableStateFlow(SigningStep.Idle)
    var failure: Throwable? = null
    var askConsent = false
    var verification: List<ValidationReport> = listOf(ValidationReport("TEST HOLDER", null, null, "PAdES-B-T", true, true, true))
    val signed = mutableListOf<String>()
    var certificateReads = 0

    override fun certificate(reader: String?): CertificateSummary { certificateReads++; return certificate }

    private fun sign(name: String, consent: Consent, requester: String?, format: String): SignResult {
        failure?.let { throw it }
        if (askConsent) {
            val answer = consent.obtain(ConsentRequest(requester, listOf(name), format, certificate))
            if (answer !is ConsentResult.Pin) throw CardError.Cancelled()
            answer.pin.fill('\u0000')
        }
        progress.value = SigningStep.Done
        signed += name
        return SignResult("%PDF-1.7\nsigned\n%%EOF\n".toByteArray(), certificate, format)
    }

    override fun signPdf(input: Document, consent: Consent, requester: String?, reader: String?, expectedCertificateSha1: String?) =
        sign(input.name, consent, requester, "PAdES-T")
    override fun signPdfVisible(input: Document, consent: Consent, placement: PdfStampPlacement, requester: String?, reader: String?, expectedCertificateSha1: String?) =
        sign(input.name, consent, requester, "PAdES-T")
    override fun signXades(files: List<Document>, level: XadesLevel, packaging: XadesPackaging, consent: Consent, requester: String?,
                           reader: String?, expectedCertificateSha1: String?, digest: XadesDigest) =
        sign(files.first().name, consent, requester, "XAdES-${level.name}")
    override fun signDigestInfo(digestInfo: ByteArray, documentName: String, consent: Consent, requester: String?, reader: String?,
                                expectedCertificateSha1: String?): RawSignature = throw CardError.NoReader()
    override fun verify(file: Document, detachedDocuments: List<Document>) = verification
}

/** Documents held in memory under `test://` URIs. */
class FakeDocumentAccess : DocumentAccess {
    val files = LinkedHashMap<Uri, Pair<String, ByteArray>>()
    val kept = mutableListOf<Uri>()
    val copies = mutableListOf<Pair<Uri, Uri>>()
    val written = mutableMapOf<Uri, ByteArray>()
    var copyResult = true
    /** Outputs outside [files] (e.g. MediaStore results) that the user may delete. */
    val deletable = mutableSetOf<Uri>()

    fun add(name: String, bytes: ByteArray = "%PDF-1.7\n%%EOF\n".toByteArray()): Uri =
        Uri.parse("test://documents/$name").also { files[it] = name to bytes }

    override fun keepAccess(uri: Uri) { kept += uri }
    override suspend fun describe(uri: Uri): PickedDocument {
        val (name, bytes) = files[uri] ?: throw java.io.FileNotFoundException(uri.toString())
        return PickedDocument(uri, name, bytes.size.toLong(), if (name.endsWith(".pdf")) "application/pdf" else "text/plain")
    }
    override fun readBytes(uri: Uri): ByteArray = files[uri]?.second ?: throw java.io.FileNotFoundException(uri.toString())
    override fun copyToCache(uri: Uri): Uri? = uri.takeIf { it in files }
    override fun delete(uri: Uri): Boolean = files.remove(uri) != null || deletable.remove(uri)
    override fun copy(source: Uri, target: Uri): Boolean { copies += source to target; return copyResult }
    override fun writeBytes(target: Uri, bytes: ByteArray): Boolean { written[target] = bytes; return true }
}

/**
 * Waits until the card is ready in [AppContainer.status], which the view model reads before signing. That flow is
 * derived from the wallet on a background dispatcher, so the wallet alone being ready says nothing about it yet.
 */
fun awaitReadyCard(container: md.moldsign.app.application.AppContainer) = awaitMain {
    container.status.value.let { !it.busy && it.wallet.selectedCard?.certificate != null }
}

/** Runs main-looper work (viewModelScope) until [condition] holds or [timeoutMs] passes. */
fun awaitMain(timeoutMs: Long = 30_000, condition: () -> Boolean) {
    val end = System.currentTimeMillis() + timeoutMs
    while (!condition()) {
        check(System.currentTimeMillis() < end) { "condition not met within $timeoutMs ms" }
        shadowOf(Looper.getMainLooper()).idle()
        Thread.sleep(10)
    }
}
