package md.moldsign.app.application

import android.net.Uri

/** Deduplicates source identities before taking grants or making temporary copies. */
class ImportDocuments(private val documents: DocumentAccess) {
    suspend fun pick(uris: List<Uri>): List<PickedDocument> = uris.distinct().map { uri ->
        documents.keepAccess(uri)
        documents.describe(uri)
    }

    fun copyShared(uris: List<Uri>): List<Uri> = uris.distinct().mapNotNull(documents::copyToCache)
}
