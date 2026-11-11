package md.moldsign.app

import android.net.Uri
import kotlinx.coroutines.runBlocking
import md.moldsign.app.application.ImportDocuments

internal object DocumentImportIntegration {
    fun run(): String = runBlocking {
        val first = Uri.parse("content://synthetic/first.txt")
        val second = Uri.parse("content://synthetic/second.txt")
        val provider = ImportDocumentFixture()
        val importer = ImportDocuments(provider)
        val selected = listOf(first, first, second, first, second)
        check(importer.pick(selected).map { it.uri } == listOf(first, second))
        check(provider.grants == listOf(first, second))
        check(importer.copyShared(selected).size == 2)
        check(provider.copies == listOf(first, second))
        check(importer.pick(emptyList()).isEmpty() && importer.copyShared(emptyList()).isEmpty())
        "document-import-duplicates:pass"
    }
}
