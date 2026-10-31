package md.moldsign.app

import md.moldsign.app.application.AppContainer
import md.moldsign.app.presentation.MainViewModel

import android.content.Intent
import android.net.Uri
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import md.moldsign.core.ActivityEntry
import md.moldsign.core.CardError
import md.moldsign.core.ConsentRequest
import md.moldsign.core.ConsentResult
import md.moldsign.core.CertificateSummary
import md.moldsign.core.ReaderSlot
import md.moldsign.core.WalletCard
import md.moldsign.core.WalletState
import java.io.File
import java.util.Calendar
import java.util.TimeZone

/**
 * DEBUG-ONLY demo mode: fake readers and cards so the wallet can be screenshotted on an emulator without
 * hardware. This file is in `src/debug`; release builds compile `src/release/.../DemoMode.kt`, a no-op, so
 * neither the fake cards nor the intent extra exist there.
 *
 * ```
 * adb shell am start -n md.moldsign.app/.MainActivity --es demo cards
 * ```
 * Scenarios: `cards` (2 ready cards, default for any other value), `one`, `reading`, `error`, `empty`
 * (reader without card), `permission` (USB access), `noreader`. The demo stops following the USB monitor until
 * the process restarts. "Recitește cardul" re-reads the fake cards with a short delay.
 */
internal object DemoMode {
    const val EXTRA = "demo"
    private const val TAG = "MoldSignDemo"

    // Fictional holders (no real person, no real certificate): SN / GN set like a real MDQSign certificate.
    private val ionPopescu = certificate("ION POPESCU", "POPESCU", "ION", "1A4C9E21B07D33F0A1C2E5D6B7F8091A2B3C4D5E", notAfterYear = 2030, month = 3)
    private val anaMindru = certificate("ANA-MARIA MÎNDRU", "MÎNDRU", "ANA-MARIA", "E47B02C9D1F0A3B5C6D7E8F9012345678ABCDEF0", notAfterYear = 2029, month = 11)
    private var fakePinJob: Job? = null
    private var fakePinRequest: ConsentRequest? = null

    fun apply(container: AppContainer, intent: Intent?, viewModel: MainViewModel) {
        val scenario = intent?.getStringExtra(EXTRA)
        if (scenario == null) {
            cancelFakePin(container)
            return
        }
        if (scenario != "pin") cancelFakePin(container)
        Log.i(TAG, "demo scenario: $scenario")
        val r1 = ReaderSlot("demo-1", "miniLector EVO", ReaderSlot.State.Card, generation = 1)
        val r2 = ReaderSlot("demo-2", "miniLector EVO #2", ReaderSlot.State.Card, generation = 2)
        val c1 = WalletCard(r1.id, r1.name, r1.generation, ionPopescu)
        val c2 = WalletCard(r2.id, r2.name, r2.generation, anaMindru)
        val state = when (scenario) {
            "one" -> WalletState(listOf(r1), listOf(c1), r1.id)
            "reading" -> WalletState(listOf(r1), listOf(c1.copy(certificate = null)), r1.id)
            "error" -> WalletState(listOf(r1, r2), listOf(c1.copy(certificate = null, problem = CardError.CardStateStuck()), c2), r1.id)
            "empty" -> WalletState(listOf(r1.copy(state = ReaderSlot.State.Empty, generation = 0)))
            "permission" -> WalletState(listOf(r1.copy(state = ReaderSlot.State.PermissionRequired, generation = 0)))
            "noreader" -> WalletState()
            else -> WalletState(listOf(r1, r2), listOf(c1, c2), r1.id)
        }
        container.showDemo(state) { card ->
            Thread.sleep(1_200)
            if (card.readerId == r2.id) anaMindru else ionPopescu
        }
        seedActivity(container)
        viewModel.signItems.value.toList().forEach(viewModel::remove)
        when (scenario) {
            "documents" -> seedSigningDocuments(container, viewModel, batch = false)
            "batch" -> seedSigningDocuments(container, viewModel, batch = true)
            "pin" -> {
                seedSigningDocuments(container, viewModel, batch = true)
                showFakePin(container)
            }
            else -> Unit
        }
    }

    /** Publishes a fictional consent request for UI evidence; no signing service or PIN vault is called. */
    private fun showFakePin(container: AppContainer) {
        val previous = cancelFakePin(container)
        val request = ConsentRequest(
            requester = null,
            documentNames = listOf("demo-contract.pdf", "demo-cerere.txt", "demo-invoice.pdf"),
            format = "PAdES-T / XAdES-T",
            certificate = ionPopescu,
        )
        fakePinRequest = request
        val job = container.scope.launch(Dispatchers.IO) {
            previous?.join()
            val result = container.consentBroker.obtain(request, timeoutMs = 30_000)
            if (result is ConsentResult.Pin) result.pin.fill('\u0000')
        }
        fakePinJob = job
    }

    /** Cancel only the pending request this demo created, then let its job clear broker state. */
    private fun cancelFakePin(container: AppContainer): Job? {
        val request = fakePinRequest
        if (request != null) {
            container.consentBroker.pending.value
                ?.takeIf { it.request === request }
                ?.answer(ConsentResult.Cancelled)
        }
        fakePinRequest = null
        val previous = fakePinJob
        previous?.cancel()
        fakePinJob = null
        return previous
    }

    /** Fictional inputs in the app cache, added through the normal document queue. */
    private fun seedSigningDocuments(container: AppContainer, viewModel: MainViewModel, batch: Boolean) {
        val dir = File(container.app.cacheDir, "demo/signing").apply { mkdirs() }
        fun file(name: String, body: String) = File(dir, name).apply { writeText(body) }
        val uris = if (batch) {
            listOf(
                Uri.fromFile(file("demo-contract.pdf", "%PDF-1.7\n% fictional demo document\n%%EOF\n")),
                Uri.fromFile(file("demo-cerere.txt", "Document fictiv pentru testarea lotului.\n")),
                Uri.fromFile(file("demo-invoice.pdf", "%PDF-1.7\n% fictional demo invoice\n%%EOF\n")),
            )
        } else {
            listOf(Uri.fromFile(file("demo-contract.pdf", "%PDF-1.7\n% fictional demo document\n%%EOF\n")))
        }
        viewModel.addForSigning(uris)
    }

    /**
     * Fictional activity: two documents backed by small files in the app cache (so they pass the reachability check),
     * one whose file is gone (pruned right away, like a deleted document), and two browser requests (always kept).
     */
    private fun seedActivity(container: AppContainer) {
        val dir = File(container.app.cacheDir, "demo").apply { mkdirs() }
        fun file(name: String, body: String) = File(dir, name).apply { writeText(body) }
        val signed = file("contract-semnat.pdf", "%PDF-1.7\n% fictional demo document\n%%EOF\n")
        val verified = file("cerere-angajare.pdf", "%PDF-1.7\n% fictional demo document\n%%EOF\n")
        val gone = File(dir, "act-vechi.pdf").apply { delete() }
        val now = System.currentTimeMillis()
        fun entry(id: String, kind: ActivityEntry.Kind, title: String, subtitle: String, ok: Boolean, minutesAgo: Long, file: File? = null) =
            ActivityEntry(id, kind, title, subtitle, ok, now - minutesAgo * 60_000, file?.let { Uri.fromFile(it).toString() })
        container.activity.replaceForDemo(
            listOf(
                entry("d1", ActivityEntry.Kind.Document, "contract-semnat.pdf", "Semnat · PAdES-T", true, 2, signed),
                entry("b1", ActivityEntry.Kind.Browser, "msign.gov.md", "Semnat · XAdES-T (SHA-1) · cerere.xml · lot", true, 25),
                entry("d2", ActivityEntry.Kind.Document, "cerere-angajare.pdf", "Verificat", true, 70, verified),
                entry("d3", ActivityEntry.Kind.Document, "act-vechi.pdf", "Semnat · XAdES-C", true, 3_000, gone),
                entry("b2", ActivityEntry.Kind.Browser, "msign.gov.md", "Eșuat · PAdES-T · PIN greșit. Încercări rămase: 2", false, 4_400),
            ),
        )
    }

    private fun certificate(holder: String, surname: String, given: String, sha1: String, notAfterYear: Int, month: Int): CertificateSummary {
        fun date(year: Int) = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { set(year, month - 1, 15, 0, 0, 0) }.time
        return CertificateSummary(
            commonName = holder,
            subjectDn = "CN=$holder,C=MD",
            issuerDn = "CN=MDQSign,C=MD",
            issuerCommonName = "MDQSign",
            notBefore = date(notAfterYear - 5),
            notAfter = date(notAfterYear),
            serialHex = sha1.take(16),
            sha1Hex = sha1,
            surname = surname,
            givenNames = given,
        )
    }
}
