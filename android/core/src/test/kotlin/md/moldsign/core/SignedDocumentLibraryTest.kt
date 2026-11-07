package md.moldsign.core

import org.junit.Assert.assertEquals
import org.junit.Test

/** Regression coverage for upgrading from the clearable, capped history-backed Documents list. */
class SignedDocumentLibraryTest {
    private fun output(id: String, uri: String = "content://outputs/$id") =
        ActivityEntry(id, ActivityEntry.Kind.Document, "$id.pdf", "Signed", true, 0L, uri, signedOutput = true)

    @Test
    fun migrationKeepsNewestSuccessfulOutputAndExcludesVerificationAndBrowserEvents() {
        val newest = output("new", "content://outputs/shared")
        val older = output("old", "content://outputs/shared")
        val other = output("other")
        val history = listOf(
            newest,
            output("verified").copy(signedOutput = false),
            output("failed").copy(ok = false),
            output("no-uri").copy(documentUri = null),
            output("browser").copy(kind = ActivityEntry.Kind.Browser),
            other,
            older,
        )
        assertEquals(listOf(newest, other), SignedDocumentLibrary.migrate(history))
        assertEquals(emptyList<ActivityEntry>(), SignedDocumentLibrary.migrate(emptyList()))
    }

    @Test
    fun savedOutputsOutliveHistoryCapAndRemainUniqueByFileUri() {
        var history = emptyList<ActivityEntry>()
        var documents = emptyList<ActivityEntry>()
        repeat(ActivityHistory.MAX_ENTRIES + 5) { index ->
            val entry = output("$index")
            history = ActivityHistory.add(history, entry)
            documents = SignedDocumentLibrary.add(documents, entry)
        }
        assertEquals(ActivityHistory.MAX_ENTRIES, history.size)
        assertEquals(ActivityHistory.MAX_ENTRIES + 5, documents.size)
        val replacement = output("updated", documents.last().documentUri!!)
        val updated = SignedDocumentLibrary.add(documents, replacement)
        assertEquals(documents.size, updated.size)
        assertEquals(replacement, updated.first())
    }
}
