package md.moldsign.app

import android.app.Application
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import androidx.annotation.StringRes
import androidx.core.net.toUri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
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

/** A document picked through the Storage Access Framework. */
data class PickedDocument(val uri: Uri, val name: String, val size: Long, val mime: String?) {
    val isPdf: Boolean get() = mime == "application/pdf" || name.endsWith(".pdf", ignoreCase = true)

    /** docs/10 / PLAN §2: PDF → PAdES-T, anything else → XAdES-T detached (the user can change it per file). */
    val defaultFormat: SignFormat get() = SignFormat.default(isPdf)
}

/** Result of "Verifică": one report per signature found. */
data class VerifyOutcome(val reports: List<ValidationReport>) {
    val verdict: Verdict get() = Verdict.of(reports)

    /** Documents a detached XAdES refers to and that the user still has to pick. */
    val missingDocuments: List<String> get() = reports.flatMap { it.missingDocuments }.distinct()
}

/** One row of the Semnează list: the document and its (auto-chosen, editable) format. */
data class SignItem(val doc: PickedDocument, val format: SignFormat = doc.defaultFormat)

sealed interface UiMessage {
    data class Error(val error: Throwable) : UiMessage
    data class Text(@StringRes val res: Int) : UiMessage

    /** A signed document was saved at [uri]: the snackbar offers to open it. */
    data class Saved(@StringRes val res: Int, val uri: Uri) : UiMessage

    /** "Why can't I sign": the status light's text. */
    data class Status(val status: AppStatus) : UiMessage
}

class MainViewModel(app: Application) : AndroidViewModel(app) {
    private val container = (app as MoldSignApp).container

    val status: StateFlow<AppStatus> = container.status
    val progress = container.signingService.progress
    val pendingConsent = container.consentBroker.pending
    val bridgeRunning = BridgeService.running
    val pinVaultAvailable: Boolean get() = container.pinVault.isAvailable()
    val activity: StateFlow<List<ActivityEntry>> = container.activity.entries

    private val _signItems = MutableStateFlow<List<SignItem>>(emptyList())
    val signItems: StateFlow<List<SignItem>> = _signItems.asStateFlow()

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

    fun consumeMessage() {
        _message.value = null
    }

    // ---------------------------------------------------------------- card wallet

    fun selectCard(readerId: String) = container.selectCard(readerId)

    fun rereadCards() = container.rereadCards()

    fun requestUsbPermission(readerId: String?) = container.readerMonitor.requestPermission(readerId)

    // ---------------------------------------------------------------- Semnează

    fun addForSigning(uris: List<Uri>) {
        if (uris.isEmpty()) return
        viewModelScope.launch {
            uris.forEach(::keepAccess)
            val docs = uris.map { describe(it) }
            _signItems.update { items -> items + docs.filter { d -> items.none { it.doc.uri == d.uri } }.map(::SignItem) }
        }
    }

    /**
     * Files shared to "Semnează" (SEND / SEND_MULTIPLE). The sender's read grant only lasts while our task lives, so each
     * file is copied into the app's cache first (emptied at process start); the list then works like picked documents.
     */
    fun receiveShared(uris: List<Uri>) {
        viewModelScope.launch {
            val copies = withContext(Dispatchers.IO) { uris.mapNotNull(::copyToCache) }
            if (copies.isEmpty()) {
                _message.value = UiMessage.Text(R.string.share_unreadable)
                return@launch
            }
            addForSigning(copies)
            showSignEvents.trySend(Unit)
        }
    }

    private fun copyToCache(uri: Uri): Uri? = runCatching {
        val context = getApplication<Application>()
        var name = uri.lastPathSegment ?: "document"
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst() && !c.isNull(0)) name = c.getString(0)
        }
        val dir = File(context.cacheDir, "$SHARED_CACHE/${UUID.randomUUID()}").apply { mkdirs() }
        val file = File(dir, name.replace('/', '_'))
        context.contentResolver.openInputStream(uri)?.use { input -> file.outputStream().use { input.copyTo(it) } } ?: return null
        file.toUri()
    }.getOrNull()

    /** "Salvează ca…": copies a signed file to the place the user picked in the system dialog. */
    fun saveCopy(source: Uri?, target: Uri?) {
        source ?: return
        target ?: return
        viewModelScope.launch {
            val ok = withContext(Dispatchers.IO) {
                runCatching {
                    val resolver = getApplication<Application>().contentResolver
                    (resolver.openInputStream(source) ?: error("unreadable")).use { input ->
                        (resolver.openOutputStream(target) ?: error("unwritable")).use { out -> input.copyTo(out) }
                    }
                }.isSuccess
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
    fun sign() {
        val items = _signItems.value
        if (items.isEmpty() || _working.value) return
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
            BatchConsent(container.consentBroker.consent).use { consent ->
                for (item in items) {
                    try {
                        val input = Document(item.doc.name, readBytes(item.doc.uri))
                        val result = service.sign(input, item.format, consent, reader = card.readerId, expectedCertificateSha1 = certificate.sha1Hex)
                        val outputName = SignFormat.outputName(item.doc.name, item.format)
                        val saved = container.signedFiles.save(outputName, if (item.format.xadesLevel == null) "application/pdf" else "application/xml", result.output)
                        container.activity.document(outputName, saved, ok = true, text(R.string.activity_signed, item.format.label))
                        lastSaved = saved
                    } catch (e: CardError.Cancelled) {
                        throw e
                    } catch (e: Throwable) {
                        log(item.doc, ok = false, text(R.string.activity_failed, item.format.label, errorText(getApplication(), e)))
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
        keepAccess(uri)
        viewModelScope.launch {
            _verifyDoc.value = describe(uri)
            _verifyDetached.value = emptyList()
            _verifyOutcome.value = null
            runVerify(firstRun = true)
        }
    }

    fun clearVerifyDoc() {
        _verifyDoc.value = null
        _verifyDetached.value = emptyList()
        _verifyOutcome.value = null
    }

    /** The signed documents a detached XAdES signature refers to (matched by file name); verifies again. */
    fun addVerifyDocuments(uris: List<Uri>) {
        if (uris.isEmpty() || _verifyDoc.value == null) return
        viewModelScope.launch {
            uris.forEach(::keepAccess)
            val docs = uris.map { describe(it) }
            _verifyDetached.update { list -> list + docs.filter { d -> list.none { it.name == d.name } } }
            runVerify(firstRun = false)
        }
    }

    private suspend fun runVerify(firstRun: Boolean) {
        val doc = _verifyDoc.value ?: return
        val before = _verifyOutcome.value
        try {
            val outcome = withContext(Dispatchers.IO) {
                val attached = _verifyDetached.value.map { Document(it.name, readBytes(it.uri)) }
                VerifyOutcome(container.signingService.verify(Document(doc.name, readBytes(doc.uri)), attached))
            }
            _verifyOutcome.value = outcome
            // one activity entry per file: the first result, or the final one once the missing documents were added
            if (firstRun || (before?.missingDocuments?.isNotEmpty() == true && outcome.missingDocuments.isEmpty())) {
                log(doc, ok = outcome.verdict == Verdict.Valid, text(verifiedActivity(outcome.verdict)))
            }
        } catch (e: Throwable) {
            _verifyOutcome.value = null
            log(doc, ok = false, text(R.string.activity_verify_failed, errorText(getApplication(), e)))
            _message.value = UiMessage.Error(e)
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
    private fun keepAccess(uri: Uri) {
        runCatching {
            getApplication<Application>().contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    // ---------------------------------------------------------------- Browser / Card

    fun setBridge(enabled: Boolean) {
        val ctx = getApplication<Application>()
        if (enabled) BridgeService.start(ctx) else BridgeService.stop(ctx)
    }

    fun deleteStoredPin() {
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
            } catch (e: CardError.Cancelled) {
                // silent (docs/09 §3.3)
            } catch (e: CardError.CardChanged) {
                // Another card is in the reader now: nothing was sent to it; show who is there and let the user retry.
                _message.value = UiMessage.Error(e)
                container.rereadCards()
            } catch (e: CardError) {
                Log.w(TAG, "card operation failed: ${e.javaClass.simpleName}")
                _message.value = UiMessage.Error(e)
            } catch (e: NotImplementedError) {
                _message.value = UiMessage.Error(e)
            } catch (e: Exception) {
                Log.w(TAG, "operation failed", e)
                _message.value = UiMessage.Error(e)
            } finally {
                _working.value = false
            }
        }
    }

    private fun readBytes(uri: Uri): ByteArray =
        getApplication<Application>().contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw CardError.Format("Cannot open the document")

    private suspend fun describe(uri: Uri): PickedDocument = withContext(Dispatchers.IO) {
        val resolver = getApplication<Application>().contentResolver
        var name = uri.lastPathSegment ?: "document"
        var size = -1L
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { c ->
            if (c.moveToFirst()) {
                c.getColumnIndex(OpenableColumns.DISPLAY_NAME).takeIf { it >= 0 && !c.isNull(it) }?.let { name = c.getString(it) }
                c.getColumnIndex(OpenableColumns.SIZE).takeIf { it >= 0 && !c.isNull(it) }?.let { size = c.getLong(it) }
            }
        }
        PickedDocument(uri, name, size, resolver.getType(uri))
    }

    companion object {
        private const val TAG = "MoldSign"

        /** Folder under `cacheDir` holding the copies of files shared to us; emptied at every process start. */
        const val SHARED_CACHE = "shared"
    }
}
