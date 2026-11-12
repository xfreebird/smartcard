package md.moldsign.app.application

import md.moldsign.core.ActivityEntry
import org.junit.Assert.*
import org.junit.Test

class DeleteSavedDocumentsTest {
    private fun entry(id: String, uri: String? = "file:///$id.pdf") = ActivityEntry(
        id, ActivityEntry.Kind.Document, "$id.pdf", "", true, 0, uri, signedOutput = true)

    @Test fun substitutedUriCannotDeleteEitherFile() {
        val saved = entry("saved")
        val deleted = mutableListOf<String>()
        val workflow = DeleteSavedDocuments { deleted += it; true }
        val result = workflow.execute(listOf(saved.copy(documentUri = "file:///other.pdf")), listOf(saved))
        assertTrue(result.failed)
        assertTrue(result.deletedIds.isEmpty())
        assertTrue(deleted.isEmpty())
    }

    @Test fun unknownAndDuplicateSelectionsDoNotDeleteExtraFiles() {
        val saved = entry("saved")
        val deleted = mutableListOf<String>()
        val result = DeleteSavedDocuments { deleted += it; true }
            .execute(listOf(entry("foreign"), saved, saved), listOf(saved))
        assertFalse(result.failed)
        assertEquals(setOf(saved.id), result.deletedIds)
        assertEquals(listOf(saved.documentUri), deleted)
    }

    @Test fun failedAndMissingLocationsRemainInTheLibrary() {
        val saved = listOf(entry("good"), entry("denied"), entry("missing", null))
        val deleted = mutableListOf<String>()
        val result = DeleteSavedDocuments { deleted += it; it == "file:///good.pdf" }.execute(saved, saved)
        assertTrue(result.failed)
        assertEquals(setOf("good"), result.deletedIds)
        assertEquals(listOf("file:///good.pdf", "file:///denied.pdf"), deleted)
    }
}
