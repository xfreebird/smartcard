package md.moldsign.app.presentation

import md.moldsign.app.application.AppContainer

import md.moldsign.app.MoldSignApp
import md.moldsign.app.R
import md.moldsign.app.application.AppStatus
import md.moldsign.app.application.DocumentAccess
import md.moldsign.app.application.PickedDocument
import md.moldsign.app.application.SignItem
import md.moldsign.app.application.VerifyOutcome
import md.moldsign.app.infrastructure.AndroidDocumentAccess
import md.moldsign.app.infrastructure.SignedFileStore
import md.moldsign.app.infrastructure.demo.DemoFixtures
import md.moldsign.app.infrastructure.demo.DemoOutputRenderer
import md.moldsign.core.Consent
import md.moldsign.core.ConsentResult

import md.moldsign.core.BatchConsent

import android.app.Application
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import androidx.annotation.StringRes
import androidx.core.net.toUri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import md.moldsign.app.bridge.BridgeService
import md.moldsign.core.ActivityEntry
import md.moldsign.core.CardError
import md.moldsign.core.Document
import md.moldsign.core.SignFormat
import md.moldsign.core.ValidationReport
import md.moldsign.core.Verdict
import java.io.File
import java.util.UUID

sealed interface UiMessage {
    data class Error(val error: Throwable) : UiMessage
    data class Text(@StringRes val res: Int) : UiMessage

    /** A signed document was saved at [uri]: the snackbar offers to open it. */
    data class Saved(@StringRes val res: Int, val uri: Uri) : UiMessage

    /** "Why can't I sign": the status light's text. */
    data class Status(val status: AppStatus) : UiMessage
}

class MainViewModel @JvmOverloads constructor(
    app: Application,
    private val documents: DocumentAccess = AndroidDocumentAccess(app),
    private val container: AppContainer = (app as MoldSignApp).container,
) : AndroidViewModel(app) {

    val demoMode: Boolean = container.userDemoMode
    val status: StateFlow<AppStatus> = container.status
    val progress = container.signingService.progress
    val pendingConsent = container.consentBroker.pending
    val bridgeRunning = BridgeService.running
    val bridgeStartupFailed = BridgeService.startupFailed
    val pinVaultAvailable: Boolean get() = !demoMode && container.pinVault.isAvailable()
    val activity: StateFlow<List<ActivityEntry>> = container.activity.entries

    private val _signedResults = MutableStateFlow<List<Pair<String, Uri>>>(emptyList())
    val signedResults = _signedResults.asStateFlow()

    private val _signItems = MutableStateFlow<List<SignItem>>(emptyList())
    val signItems: StateFlow<List<SignItem>> = _signItems.asStateFlow()

    private var verifyJob: kotlinx.coroutines.Job? = null
    private val _verifiedDocuments = MutableStateFlow<List<Pair<PickedDocument, VerifyOutcome>>>(emptyList())
    val verifiedDocuments = _verifiedDocuments.asStateFlow()

    fun pickMultipleForVerify(uris: List<Uri>) {
        if (demoMode) { pickForVerify(uris.firstOrNull()); return }
        verifyJob?.cancel()
        verifyJob = viewModelScope.launch {
            _verifiedDocuments.value = emptyList()
            _verifyDoc.value = null
            _verifyOutcome.value = null
            for (uri in uris) {
                documents.keepAccess(uri)
                _verifyDoc.value = documents.describe(uri)
                _verifyDetached.value = emptyList()
                _verifyOutcome.value = null
                runVerify(firstRun = true)
            }
        }
    }

    private val _verifyDoc = MutableStateFlow<PickedDocument?>(null)
    val verifyDoc: StateFlow<PickedDocument?> = _verifyDoc.asStateFlow()

    private val _verifyDetached = MutableStateFlow<List<PickedDocument>>(emptyList())
    val verifyDetached: StateFlow<List<PickedDocument>> = _verifyDetached.asStateFlow()

    private val _verifyOutcome = MutableStateFlow<VerifyOutcome?>(null)
    val verifyOutcome: StateFlow<VerifyOutcome?> = _verifyOutcome.asStateFlow()

    private val _message = MutableStateFlow<UiMessage?>(null)
    val message: StateFlow<UiMessage?> = _message.asStateFlow()

    private val _working = MutableStateFlow(false)
    val working: StateFlow<Boolean> = _working.asStateFlow()

    private val showSignEvents = Channel<Unit>(Channel.CONFLATED)

    /** One event per batch of files from the share sheet: the UI goes to the Semnează tab (delivered once, even if late). */
    val showSign: Flow<Unit> = showSignEvents.receiveAsFlow()

    init { if (demoMode) seedPreviewDocuments() }

    private fun seedPreviewDocuments() {
        _signItems.value = listOf("DEMO-contract.pdf", "DEMO-request.pdf").map {
            SignItem(PickedDocument(Uri.parse("demo://sample/$it"), it, DemoFixtures.samplePdf.size.toLong(), "application/pdf"))
        }
    }

    fun consumeMessage() {
        _message.value = null
    }

    // ---------------------------------------------------------------- card wallet

    fun selectCard(readerId: String) {
        if (!_working.value && !container.busy.value) container.selectCard(readerId)
    }

    fun rereadCards() = container.rereadCards()

    fun requestUsbPermission(readerId: String?) = container.readerMonitor.requestPermission(readerId)

    // ---------------------------------------------------------------- Semnează

    fun receiveDroppedForSigning(uris: List<Uri>, releasePermission: () -> Unit = {}) {
        if (demoMode) { releasePermission(); seedPreviewDocuments(); return }
        viewModelScope.launch {
            val copies = try { withContext(Dispatchers.IO) { uris.mapNotNull(documents::copyToCache) } }
            finally { releasePermission() }
            if (copies.isEmpty()) _message.value = UiMessage.Text(R.string.share_unreadable)
            else addForSigning(copies)
        }
    }

    fun addForSigning(uris: List<Uri>) {
        if (demoMode) { seedPreviewDocuments(); return }
        if (uris.isEmpty()) return
        viewModelScope.launch {
            uris.forEach(documents::keepAccess)
            val docs = uris.map { documents.describe(it) }
            _signItems.update { items -> items + docs.filter { d -> items.none { it.doc.uri == d.uri } }.map(::SignItem) }
        }
    }

    /**
     * Files shared to "Semnează" (SEND / SEND_MULTIPLE). The sender's read grant only lasts while our task lives, so each
     * file is copied into the app's cache first (emptied at process start); the list then works like picked documents.
     */
    fun receiveShared(uris: List<Uri>) {
        if (demoMode) { seedPreviewDocuments(); showSignEvents.trySend(Unit); return }
        viewModelScope.launch {
            val copies = withContext(Dispatchers.IO) { uris.mapNotNull(documents::copyToCache) }
            if (copies.isEmpty()) {
                _message.value = UiMessage.Text(R.string.share_unreadable)
                return@launch
            }
            addForSigning(copies)
            showSignEvents.trySend(Unit)
        }
    }

    /** "Salvează ca…": copies a signed file to the place the user picked in the system dialog. */
    fun saveCopy(source: Uri?, target: Uri?) {
        if (demoMode && container.activity.entries.value.none {
                it.documentUri == source?.toString() && it.title.startsWith("DEMO-")
            }) return
        source ?: return
        target ?: return
        viewModelScope.launch {
            val ok = withContext(Dispatchers.IO) {
documents.copy(source, target)
            }
            _message.value = UiMessage.Text(if (ok) R.string.copy_saved else R.string.copy_failed)
        }
    }

    fun setFormat(item: SignItem, format: SignFormat) {
        _signItems.update { items -> items.map { if (it.doc.uri == item.doc.uri) it.copy(format = format) else it } }
    }

    fun remove(item: SignItem) {
        _signItems.update { items -> items.filterNot { it.doc.uri == item.doc.uri } }
    }

    /**
     * Signs every listed document with the card selected in the wallet and one PIN entry. The core reads that
     * card's certificate and compares its SHA-1 before the PIN sheet opens (identity guard, docs/09 §3.1b): a
     * swapped card fails with CardError.CardChanged and the wallet is re-read.
     * The format chosen per file goes to the core as is (`SigningService.sign`): a PDF can be PAdES-T or a detached
     * XAdES over its bytes. Each outcome is logged in the activity list.
     * The result is saved by `SignedFileStore` and the activity entry points at it; "Salvează ca…" in Activity copies it elsewhere.
     * TODO(AND-06): load the stored PIN (BiometricPrompt) before the sheet; delete it on CardError.WrongPin.
     */
    fun sign() = signItems(_signItems.value)

    /** Retry only the failed document, with a fresh explicit consent/PIN session. */
    fun retry(item: SignItem) {
        val current = _signItems.value.firstOrNull { it.doc.uri == item.doc.uri && it.error != null } ?: return
        signItems(listOf(current))
    }

    private fun signItems(items: List<SignItem>) {
        if (items.isEmpty() || _working.value) return
        _signedResults.value = emptyList()
        if (demoMode) {
            if (_signItems.value.isEmpty()) return
            runJob(busyLight = true) {
                // Input comes from a fixed fixture, never from a picked/shared real document or the vault.
                val card = container.wallet.value.selectedCard
                var lastPreview: Uri? = null
                items.forEach { item ->
                    container.signingService.sign(
                        Document(item.doc.name, DemoFixtures.samplePdf), item.format,
                        Consent { ConsentResult.Cancelled }, reader = card?.readerId,
                    )
                    val fixtureName = item.doc.name.removePrefix("DEMO-").substringBeforeLast('.')
                    val outputName = "DEMO-$fixtureName-NOT-SIGNED.pdf"
                    val saved = container.signedFiles.save(outputName, "application/pdf", DemoOutputRenderer.render())
                    container.activity.document(outputName, saved, ok = true, text(R.string.demo_mode_result))
                    _signedResults.update { it + (outputName to saved) }
                    lastPreview = saved
                    _signItems.update { list -> list.filterNot { it.doc.uri == item.doc.uri } }
                }
                lastPreview?.let { _message.value = UiMessage.Saved(R.string.demo_mode_result, it) }
            }
            return
        }
        if (container.isDemo) return
        val status = container.status.value
        val card = status.wallet.selectedCard
        val certificate = card?.certificate
        if (card == null || certificate == null || status.busy) {
            _message.value = UiMessage.Status(status)
            return
        }
        runJob(busyLight = true) {
            val service = container.signingService
            var lastSaved: Uri? = null
            BatchConsent(
                container.consentBroker.consent,
                documentNames = items.map { it.doc.name },
                batchFormat = items.map { it.format.label }.distinct().joinToString(" · "),
                expectedCertificateSha1 = certificate.sha1Hex,
                allowedFormats = items.map { it.format.label }.toSet(),
            ).use { consent ->
                for (item in items) {
                    _signItems.update { list -> list.map { if (it.doc.uri == item.doc.uri) it.copy(error = null) else it } }
                    try {
                        val input = Document(item.doc.name, documents.readBytes(item.doc.uri))
                        val result = service.sign(input, item.format, consent, reader = card.readerId, expectedCertificateSha1 = certificate.sha1Hex)
                        val outputName = SignFormat.outputName(item.doc.name, item.format)
                        val saved = container.signedFiles.save(outputName, if (item.format.xadesLevel == null) "application/pdf" else "application/xml", result.output)
                        container.activity.document(outputName, saved, ok = true, text(R.string.activity_signed, item.format.label))
                        _signedResults.update { it + (outputName to saved) }
                        lastSaved = saved
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: CardError.Cancelled) {
                        throw e
                    } catch (e: Throwable) {
                        _signItems.update { list -> list.map { if (it.doc.uri == item.doc.uri) it.copy(error = e) else it } }
                        log(item.doc, ok = false, text(R.string.activity_failed, item.format.label, errorText(getApplication(), e)))
                        if (e is CardError.Format || e is CardError.Network || e is java.io.IOException) continue
                        throw e
                    }
                    _signItems.update { list -> list.filterNot { it.doc.uri == item.doc.uri } }
                }
            }
            lastSaved?.let { _message.value = UiMessage.Saved(if (SignedFileStore.inDownloads) R.string.signed_saved else R.string.signed_saved_app, it) }
        }
    }

    // ---------------------------------------------------------------- Verifică

    /** Picking a file verifies it at once (offline, no card, no PIN); the result stays on screen. */
    fun pickForVerify(uri: Uri?) {
        uri ?: return
        if (demoMode) {
            _verifyDoc.value = PickedDocument(Uri.parse("demo://sample/DEMO-contract.pdf"), "DEMO-contract.pdf", DemoFixtures.samplePdf.size.toLong(), "application/pdf")
            _verifyDetached.value = emptyList()
            _verifyOutcome.value = VerifyOutcome(container.signingService.verify(Document("DEMO-contract.pdf", DemoFixtures.samplePdf)))
            return
        }
        documents.keepAccess(uri)
        verifyJob?.cancel()
        verifyJob = viewModelScope.launch {
            _verifyDoc.value = documents.describe(uri)
            _verifyDetached.value = emptyList()
            _verifyOutcome.value = null
            runVerify(firstRun = true)
        }
    }

    /** Android drag grants last only while the drop is active, so copy the URI before releasing the grant. */
    fun receiveDroppedForVerify(uri: Uri, releasePermission: () -> Unit = {}) = receiveDroppedForVerify(listOf(uri), releasePermission)

    fun receiveDroppedForVerify(uris: List<Uri>, releasePermission: () -> Unit = {}) {
        if (demoMode) { releasePermission(); pickForVerify(uris.firstOrNull()); return }
        verifyJob?.cancel()
        verifyJob = viewModelScope.launch {
            val cached = try { withContext(Dispatchers.IO) { uris.mapNotNull { documents.copyToCache(it) } } }
            finally { releasePermission() }
            if (cached.isEmpty()) _message.value = UiMessage.Text(R.string.share_unreadable)
            else pickMultipleForVerify(cached)
        }
    }

    fun clearVerifyResults() {
        verifyJob?.cancel()
        _verifiedDocuments.value = emptyList()
        _verifyDoc.value = null
        _verifyDetached.value = emptyList()
        _verifyOutcome.value = null
    }

    fun removeVerifiedDocument(uri: Uri) {
        _verifiedDocuments.update { entries -> entries.filterNot { it.first.uri == uri } }
        if (_verifyDoc.value?.uri == uri) {
            verifyJob?.cancel()
            _verifyDoc.value = null
            _verifyDetached.value = emptyList()
            _verifyOutcome.value = null
        }
    }

    fun clearVerifyDoc() { _verifyDoc.value?.uri?.let(::removeVerifiedDocument) }

    /** The signed documents a detached XAdES signature refers to (matched by file name); verifies again. */
    fun addVerifyDocuments(uris: List<Uri>) {
        if (demoMode) return
        if (uris.isEmpty() || _verifyDoc.value == null) return
        verifyJob?.cancel()
        verifyJob = viewModelScope.launch {
            uris.forEach(documents::keepAccess)
            val docs = uris.map { documents.describe(it) }
            _verifyDetached.update { list -> list + docs.filter { d -> list.none { it.name == d.name } } }
            runVerify(firstRun = false)
        }
    }

    private suspend fun runVerify(firstRun: Boolean) {
        val doc = _verifyDoc.value ?: return
        val before = _verifyOutcome.value
        try {
            val outcome = withContext(Dispatchers.IO) {
                val attached = _verifyDetached.value.map { Document(it.name, documents.readBytes(it.uri)) }
                VerifyOutcome(container.signingService.verify(Document(doc.name, documents.readBytes(doc.uri)), attached))
            }
            _verifyOutcome.value = outcome
            _verifiedDocuments.update { entries -> entries.filterNot { it.first.uri == doc.uri } + (doc to outcome) }
            // one activity entry per file: the first result, or the final one once the missing documents were added
            if (firstRun || (before?.missingDocuments?.isNotEmpty() == true && outcome.missingDocuments.isEmpty())) {
                log(doc, ok = outcome.verdict == Verdict.Valid, text(verifiedActivity(outcome.verdict)))
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            _verifyOutcome.value = null
            log(doc, ok = false, text(R.string.activity_verify_failed, errorText(getApplication(), e)))
            if (_signItems.value.none { it.error === e }) _message.value = UiMessage.Error(e)
        }
    }

    private fun verifiedActivity(verdict: Verdict) = when (verdict) {
        Verdict.Valid -> R.string.activity_verified
        Verdict.Invalid -> R.string.activity_verified_invalid
        Verdict.Unconfirmed -> R.string.activity_verified_unconfirmed
        Verdict.NoSignature -> R.string.activity_verified_none
    }

    // ---------------------------------------------------------------- Activitate

    /** Re-checks that every document entry is still reachable (called when the list is shown). */
    fun pruneActivity() {
        container.activity.prune()
    }

    /** "Golește lista", after the confirmation dialog. */
    fun clearActivity() = container.activity.clear()

    private fun log(doc: PickedDocument, ok: Boolean, subtitle: String) = container.activity.document(doc.name, doc.uri, ok, subtitle)

    private fun text(res: Int, vararg args: Any): String = getApplication<Application>().getString(res, *args)

    /** Keeps read access across restarts so activity entries can be opened later (and pruned when it is revoked). */
    // ---------------------------------------------------------------- Browser / Card

    fun setBridge(enabled: Boolean) {
        val ctx = getApplication<Application>()
        if (enabled && !container.isDemo) BridgeService.start(ctx) else BridgeService.stop(ctx)
    }

    fun deleteStoredPin() {
        if (container.isDemo) return
        val certId = container.wallet.value.selectedCard?.certificate?.sha1Hex ?: return
        viewModelScope.launch {
            container.pinVault.delete(certId)
            _message.value = UiMessage.Text(R.string.pin_stored_deleted)
        }
    }

    private fun runJob(busyLight: Boolean, block: suspend () -> Unit) {
        if (_working.value) return
        _working.value = true
        viewModelScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    if (busyLight) container.whileBusy { block() } else block()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: CardError.Cancelled) {
                // silent (docs/09 §3.3)
            } catch (e: CardError.CardChanged) {
                // Another card is in the reader now: nothing was sent to it; show who is there and let the user retry.
                if (_signItems.value.none { it.error === e }) _message.value = UiMessage.Error(e)
                container.rereadCards()
            } catch (e: CardError) {
                Log.w(TAG, "card operation failed: ${e.javaClass.simpleName}")
                if (_signItems.value.none { it.error === e }) _message.value = UiMessage.Error(e)
            } catch (e: NotImplementedError) {
                if (_signItems.value.none { it.error === e }) _message.value = UiMessage.Error(e)
            } catch (e: Exception) {
                Log.w(TAG, "operation failed", e)
                if (_signItems.value.none { it.error === e }) _message.value = UiMessage.Error(e)
            } finally {
                _working.value = false
            }
        }
    }

    companion object {
        private const val TAG = "MoldSign"


    }
}
