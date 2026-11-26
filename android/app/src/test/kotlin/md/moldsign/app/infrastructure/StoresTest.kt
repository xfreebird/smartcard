package md.moldsign.app.infrastructure

import android.app.Application
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import md.moldsign.app.application.BookmarkIcon
import md.moldsign.app.application.BrowserBookmark
import md.moldsign.app.testing.FakeMediaStore
import md.moldsign.app.testing.awaitMain
import md.moldsign.app.testing.resetStaticAndroidState
import md.moldsign.core.ActivityEntry
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

/** Private preferences and file stores: bookmarks, activity history, signed outputs and protected files. */
@RunWith(RobolectricTestRunner::class)
@Config(application = Application::class)
class StoresTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    @Before fun setUp() { resetStaticAndroidState(); FakeMediaStore.install() }
    @After fun tearDown() = scope.cancel()

    @Test fun bookmarksStartWithBuiltinsAndStayEditable() {
        val builtin = BrowserBookmark("builtin:https://msign.gov.md/", "MSign", "https://msign.gov.md/", BookmarkIcon.Document, builtinImage = 1)
        val store = BrowserBookmarksStore(app, listOf(builtin))
        assertEquals(listOf(builtin), store.load())
        assertFalse(store.addOrUpdate(null, "  ", "https://example.md", BookmarkIcon.Star, false))
        assertFalse(store.addOrUpdate(null, "Bad", "javascript:alert(1)", BookmarkIcon.Star, false))
        assertTrue(store.addOrUpdate(null, " Example ", "example.md", BookmarkIcon.Star, false))
        val added = store.load().last()
        assertEquals("Example", added.title)
        assertEquals("https://example.md", added.url)
        assertTrue(store.addOrUpdate(builtin, "MSign portal", "https://msign.gov.md/", BookmarkIcon.Document, keepWebsiteImage = true))
        assertEquals(1, store.load().first().builtinImage)
        store.remove(added)
        assertEquals(listOf("MSign portal"), store.load().map { it.title })
        store.remove(store.load().single())
        assertTrue("an emptied list stays empty", BrowserBookmarksStore(app, listOf(builtin)).load().isEmpty())
        app.getSharedPreferences("browser-bookmarks", 0).edit().putString("items", "not json").commit()
        assertEquals(listOf(builtin), BrowserBookmarksStore(app, listOf(builtin)).load())
    }

    @Test fun activityHistoryPersistsAndPrunesUnreachableDocuments() {
        val log = ActivityLog(app, scope)
        val present = File(app.filesDir, "present-semnat.pdf").apply { writeText("%PDF") }
        log.document("present-semnat.pdf", Uri.fromFile(present), ok = true, subtitle = "Signed", signedOutput = true)
        log.document("gone-semnat.pdf", Uri.fromFile(File(app.filesDir, "gone.pdf")), ok = true, subtitle = "Signed", signedOutput = true)
        log.document("foreign.pdf", Uri.parse("content://elsewhere/doc"), ok = true, subtitle = "Verified")
        log.browser("msign.gov.md", ok = false, subtitle = "Failed")
        log.document("protected.txt.symmetric.p7m", ProtectedFileStore(app).save("protected.txt.symmetric.p7m", "x".toByteArray()), ok = true,
            subtitle = "Encrypted", protectionOperation = "encrypt")
        assertEquals(5, log.entries.value.size)
        log.prune()
        awaitMain { log.entries.value.size == 3 }
        assertEquals(setOf("present-semnat.pdf", "protected.txt.symmetric.p7m", "msign.gov.md"), log.entries.value.map { it.title }.toSet())
        // The document library is not pruned with the history.
        assertEquals(3, log.signedDocuments.value.size)

        val reloaded = ActivityLog(app, scope)
        assertEquals(log.entries.value, reloaded.entries.value)
        reloaded.removeSignedDocuments(setOf(reloaded.signedDocuments.value.first().id))
        assertEquals(2, reloaded.signedDocuments.value.size)
        reloaded.clear()
        assertTrue(ActivityLog(app, scope).entries.value.isEmpty())
        assertEquals(ActivityEntry.Kind.Document, reloaded.signedDocuments.value.first().kind)
    }

    @Test fun signedOutputsGoToDownloadsAndProtectedFilesStayPrivate() {
        val uri = SignedFileStore(app).save("contract-semnat.pdf", "application/pdf", "%PDF signed".toByteArray())
        assertEquals("media", uri.authority)
        assertEquals(listOf("contract-semnat.pdf"), FakeMediaStore.names())
        assertArrayEquals("%PDF signed".toByteArray(), app.contentResolver.openInputStream(uri)!!.use { it.readBytes() })
        assertTrue(SignedFileStore.inDownloads)

        val store = ProtectedFileStore(app)
        val first = store.save("../report.p7m", "a".toByteArray())
        val second = store.save("..", "b".toByteArray())
        assertEquals("${app.packageName}.protected-files", first.authority)
        assertTrue(first.path!!.endsWith("/.._report.p7m"))
        assertTrue(second.path!!.endsWith("/document"))
        assertArrayEquals("b".toByteArray(), app.contentResolver.openInputStream(second)!!.use { it.readBytes() })
    }
}
