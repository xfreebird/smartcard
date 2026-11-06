package md.moldsign.app.application

import android.app.Application
import android.net.Uri
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import md.moldsign.core.*
import java.io.File

/** Session-only bridge preview. No PIN or PDF bytes go into preferences, logs or activity history. */
class StampBroker(private val app: Application) {
    class Pending(val item: SignItem, val holder: String, val requester: String?, private val result: CompletableDeferred<PdfStampDecision>) {
        fun answer(value: PdfStampDecision) { result.complete(value) }
    }
    private val state = MutableStateFlow<Pending?>(null)
    val pending = state.asStateFlow()
    var enabled: Boolean
        get() = app.getSharedPreferences("pdf-stamps", 0).getBoolean("browser", false)
        set(value) { app.getSharedPreferences("pdf-stamps", 0).edit().putBoolean("browser", value).apply() }

    fun obtain(document: Document, certificate: CertificateSummary, requester: String?): PdfStampDecision {
        if (!enabled) return PdfStampDecision.Proceed(null)
        val file = File.createTempFile("bridge-pdf-", ".pdf", app.cacheDir)
        try {
            file.writeBytes(document.bytes)
            val answer = CompletableDeferred<PdfStampDecision>()
            state.value = Pending(SignItem(PickedDocument(Uri.fromFile(file), document.name, file.length(), "application/pdf"), stamp = PdfStampPlacement()), certificate.commonName, requester, answer)
            return runBlocking { withTimeoutOrNull(120_000) { answer.await() } ?: PdfStampDecision.Cancel }
        } finally { state.value = null; file.delete() }
    }
}
