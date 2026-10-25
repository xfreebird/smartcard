package md.moldsign.app

import android.app.Application
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import androidx.annotation.StringRes
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import md.moldsign.app.bridge.BridgeService
import md.moldsign.core.CardError
import md.moldsign.core.Document
import md.moldsign.core.XadesLevel
import md.moldsign.core.XadesPackaging

/** A document picked through the Storage Access Framework. */
data class PickedDocument(val uri: Uri, val name: String, val size: Long, val mime: String?) {
    val isPdf: Boolean get() = mime == "application/pdf" || name.endsWith(".pdf", ignoreCase = true)

    /** docs/10 / PLAN §2: PDF → PAdES-T, anything else → XAdES-T detached. */
    val defaultFormat: String get() = if (isPdf) "PAdES-T" else "XAdES-T"
}

sealed interface UiMessage {
    data class Error(val error: Throwable) : UiMessage
    data class Text(@StringRes val res: Int) : UiMessage
}

class MainViewModel(app: Application) : AndroidViewModel(app) {
    private val container = (app as MoldSignApp).container

    val readerState = container.readerMonitor.state
    val certificate = container.certificate
    val cardError = container.cardError
    val progress = container.signingService.progress
    val pendingConsent = container.consentBroker.pending
    val bridgeRunning = BridgeService.running
    val pinVaultAvailable: Boolean get() = container.pinVault.isAvailable()

    private val _signDoc = MutableStateFlow<PickedDocument?>(null)
    val signDoc: StateFlow<PickedDocument?> = _signDoc.asStateFlow()

    private val _signFormat = MutableStateFlow<String?>(null)
    val signFormat: StateFlow<String?> = _signFormat.asStateFlow()

    private val _verifyDoc = MutableStateFlow<PickedDocument?>(null)
    val verifyDoc: StateFlow<PickedDocument?> = _verifyDoc.asStateFlow()

    private val _message = MutableStateFlow<UiMessage?>(null)
    val message: StateFlow<UiMessage?> = _message.asStateFlow()

    private val _working = MutableStateFlow(false)
    val working: StateFlow<Boolean> = _working.asStateFlow()

    fun consumeMessage() {
        _message.value = null
    }

    fun requestUsbPermission() = container.readerMonitor.requestPermission()

    fun readCertificate() {
        container.readCertificate()
    }

    fun pickForSigning(uri: Uri?) {
        uri ?: return
        viewModelScope.launch {
            val doc = describe(uri)
            _signDoc.value = doc
            _signFormat.value = doc.defaultFormat
        }
    }

    fun setSignFormat(format: String) {
        _signFormat.value = format
    }

    fun clearSignDoc() {
        _signDoc.value = null
        _signFormat.value = null
    }

    fun pickForVerify(uri: Uri?) {
        uri ?: return
        viewModelScope.launch { _verifyDoc.value = describe(uri) }
    }

    fun clearVerifyDoc() {
        _verifyDoc.value = null
    }

    /**
     * Signs the picked document. The PIN sheet appears when the core asks for consent (ConsentBroker).
     * TODO(AND-07): write `<name>-semnat.<ext>` through SAF CreateDocument (D-06), share target "Semnează".
     * TODO(AND-06): on CardError.WrongPin delete the stored PIN for this certificate.
     */
    fun sign() {
        val doc = _signDoc.value ?: return
        val format = _signFormat.value ?: doc.defaultFormat
        runCardJob {
            val input = Document(doc.name, readBytes(doc.uri))
            val service = container.signingService
            val consent = container.consentBroker.consent
            if (format.startsWith("PAdES")) {
                service.signPdf(input, consent)
            } else {
                val level = XadesLevel.valueOf(format.removePrefix("XAdES-"))
                service.signXades(listOf(input), level, XadesPackaging.Detached, consent)
            }
        }
    }

    fun verify() {
        val doc = _verifyDoc.value ?: return
        runCardJob {
            container.signingService.verify(Document(doc.name, readBytes(doc.uri)))
            // TODO(AND-01): render VerdictBadge + SignatureCards from the reports.
        }
    }

    fun setBridge(enabled: Boolean) {
        val ctx = getApplication<Application>()
        if (enabled) BridgeService.start(ctx) else BridgeService.stop(ctx)
    }

    fun deleteStoredPin() {
        val certId = certificate.value?.sha1Hex ?: return
        viewModelScope.launch {
            container.pinVault.delete(certId)
            _message.value = UiMessage.Text(R.string.pin_stored_deleted)
        }
    }

    private fun runCardJob(block: suspend () -> Unit) {
        if (_working.value) return
        _working.value = true
        viewModelScope.launch {
            try {
                withContext(Dispatchers.IO) { block() }
            } catch (e: CardError.Cancelled) {
                // silent (docs/09 §3.3)
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

    private companion object {
        const val TAG = "MoldSign"
    }
}
