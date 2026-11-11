package md.moldsign.app.application

import android.net.Uri
import kotlinx.coroutines.CancellationException
import md.moldsign.core.BatchConsent
import md.moldsign.core.CardError
import md.moldsign.core.Consent
import md.moldsign.core.SignFormat
import md.moldsign.core.SigningService
import java.io.IOException

/** Executes on the caller's worker dispatcher; emits results without owning UI state or localized copy. */
class SignDocuments(
    private val signing: SigningService,
    private val data: DocumentDataProvider,
    private val outputs: DocumentOutputStore,
    private val outputName: (SignItem) -> String = { SignFormat.outputName(it.doc.name, it.format) },
) {
    sealed interface Event {
        val item: SignItem
        data class Started(override val item: SignItem) : Event
        data class Saved(override val item: SignItem, val name: String, val uri: Uri) : Event
        data class Failed(override val item: SignItem, val error: Throwable) : Event
    }

    fun execute(items: List<SignItem>, reader: String, certificateSHA1: String,
                authorize: Consent, emit: (Event) -> Unit) {
        BatchConsent(
            authorize,
            documentNames = items.map { it.doc.name },
            batchFormat = items.map { it.format.label }.distinct().joinToString(" · "),
            expectedCertificateSha1 = certificateSHA1,
            allowedFormats = items.map { it.format.label }.toSet(),
        ).use { consent ->
            for (item in items) {
                emit(Event.Started(item))
                val saved = try {
                    val result = signing.sign(data.document(item.doc), item.format, consent,
                        reader = reader, expectedCertificateSha1 = certificateSHA1, placement = item.stamp)
                    val name = outputName(item)
                    val uri = outputs.save(name, if (item.format.xadesLevel == null) "application/pdf" else "application/xml", result.output)
                    Event.Saved(item, name, uri)
                } catch (error: CancellationException) {
                    throw error
                } catch (error: CardError.Cancelled) {
                    throw error
                } catch (error: Exception) {
                    emit(Event.Failed(item, error))
                    if (error is CardError.Format || error is CardError.Network || error is IOException) continue
                    throw error
                }
                // Presentation failures must not be misclassified as signing failures or retried.
                emit(saved)
            }
        }
    }
}
