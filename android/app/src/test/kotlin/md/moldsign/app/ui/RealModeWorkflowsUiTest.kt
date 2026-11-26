package md.moldsign.app.ui

import android.net.Uri
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.performTextReplacement
import md.moldsign.app.R
import md.moldsign.app.application.AppContainer
import md.moldsign.app.testing.FakeMediaStore
import md.moldsign.app.testing.FakeReaderGateway
import md.moldsign.app.testing.FakeSigningService
import md.moldsign.core.ConsentResult
import md.moldsign.core.ReaderSlot
import md.moldsign.core.ValidationReport
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.File

/**
 * The real (non-demo) app with fake reader and card adapters: pickers answered like the system would,
 * the PIN sheet, results, verification and file protection.
 */
class RealModeWorkflowsUiTest : AppUiTest() {
    private val signing = FakeSigningService()
    private val readers = FakeReaderGateway()

    @Before fun realGraph() {
        FakeMediaStore.install()
        installContainer(AppContainer(app, signingFactory = { signing }, readerFactory = { _, _ -> readers }))
        compose.waitUntil(10_000) { app.container.wallet.value.readyCards.isNotEmpty() }
    }

    private fun file(name: String, body: String) = Uri.fromFile(File(app.filesDir, name).apply { writeText(body) })

    @Test fun signWithTheReaderThroughThePinSheet() {
        signing.askConsent = true
        launch(capture = false).use { scenario ->
            clickTag("sign.method")
            clickTag("sign.reader")
            drawAll()
            clickTag("sign.pickFiles")
            answerPicker(scenario, file("contract.pdf", "%PDF-1.7\n%%EOF\n"), file("note.txt", "note"))
            awaitTag("sign.submit")
            drawAll()
            compose.mainClock.autoAdvance = false
            clickTag("sign.submit")
            compose.waitUntil(10_000) { app.container.consentBroker.pending.value != null }
            compose.mainClock.advanceTimeBy(500)
            drawAll()
            compose.onAllNodes(hasSetTextAction()).fetchSemanticsNodes()
            tag("pin.field").performTextReplacement("1234")
            compose.mainClock.advanceTimeBy(100)
            clickTag("pin.confirm")
            compose.mainClock.autoAdvance = true
            compose.waitUntil(20_000) { signing.signed.size == 2 }
            awaitText("contract-semnat.pdf")
            drawAll()
            assertTrue(FakeMediaStore.names().containsAll(listOf("contract-semnat.pdf", "note-semnat.xml")))
            clickTag("sign.clearResults")
            navigate("activity")
            awaitText("contract-semnat.pdf")
            drawAll()
            clickTag("documents.historyTab")
            drawAll()
            clickTag("documents.savedTab")
            clickText("contract-semnat.pdf")
            drawAll()
        }
    }

    @Test fun cancelledPinLeavesTheQueue() {
        signing.askConsent = true
        launch(capture = false).use { scenario ->
            clickTag("sign.method")
            clickTag("sign.reader")
            clickTag("sign.pickFiles")
            answerPicker(scenario, file("one.pdf", "%PDF-1.7\n%%EOF\n"))
            awaitTag("sign.submit")
            compose.mainClock.autoAdvance = false
            clickTag("sign.submit")
            compose.waitUntil(10_000) { app.container.consentBroker.pending.value != null }
            compose.mainClock.advanceTimeBy(500)
            clickTag("pin.cancel")
            compose.mainClock.autoAdvance = true
            compose.waitUntil(10_000) { app.container.consentBroker.pending.value == null && !app.container.busy.value }
            assertTrue(signing.signed.isEmpty())
            assertTrue(showsTag("sign.submit"))
        }
    }

    @Test fun pickerCancellationAndReaderStates() {
        launch(capture = false).use { scenario ->
            clickTag("sign.method")
            clickTag("sign.reader")
            clickTag("sign.pickFiles")
            answerPicker(scenario, cancel = true)
            assertTrue(showsTag("sign.pickFiles"))
            for (state in listOf(ReaderSlot.State.Empty, ReaderSlot.State.PermissionRequired, ReaderSlot.State.Error)) {
                readers.readers.value = listOf(ReaderSlot("usb-1", "Test reader", state, 0))
                compose.waitForIdle()
                drawAll()
            }
            readers.readers.value = emptyList()
            compose.waitForIdle()
            drawAll()
            readers.readers.value = listOf(ReaderSlot("usb-1", "Test reader", ReaderSlot.State.Card, 5), ReaderSlot("usb-2", "Test reader #2", ReaderSlot.State.Card, 6))
            compose.waitUntil(10_000) { app.container.wallet.value.readyCards.size == 2 }
            drawAll()
        }
    }

    @Test fun verifyPickedDocumentsAndDetachedSignature() {
        launch(capture = false).use { scenario ->
            navigate("verify")
            clickTag("verify.pickFiles")
            answerPicker(scenario, file("signed.pdf", "%PDF-1.7\n%%EOF\n"))
            awaitText(string(R.string.verdict_valid))
            drawAll()
            signing.verification = listOf(ValidationReport("X", null, null, "XAdES-T", true, true, true, missingDocuments = listOf("doc.txt")))
            clickTag("verify.pickFiles")
            answerPicker(scenario, file("sig.xml", "<xml/>"))
            awaitText("doc.txt")
            drawAll()
            signing.verification = listOf(ValidationReport("X", null, null, "XAdES-T", false, true, false))
            clickText(string(R.string.verify_add_document))
            answerPicker(scenario, file("doc.txt", "doc"))
            awaitText(string(R.string.verdict_invalid))
            drawAll()
            clickTag("verify.clearResults")
            assertFalse(shows(string(R.string.verdict_invalid)))
        }
    }

    @Test fun passwordProtectionFromTheFilesMenu() {
        launch(capture = false).use { scenario ->
            navigate("activity")
            clickDescription(string(R.string.action_more))
            clickMenuItem(string(R.string.protect_title))
            awaitText(string(R.string.protect_choose_file))
            clickText(string(R.string.protect_choose_file))
            answerPicker(scenario, file("secret.txt", "classified"))
            awaitText("secret.txt")
            val fields = compose.onAllNodes(hasSetTextAction())
            fields[0].performTextReplacement("correct horse")
            fields[1].performTextReplacement("correct horse")
            compose.waitForIdle()
            clickText(string(R.string.protect_help))
            drawAll()
            compose.onAllNodes(androidx.compose.ui.test.hasText(string(R.string.protect_encrypt)) and androidx.compose.ui.test.hasClickAction())
                .fetchSemanticsNodes().size.let { assertTrue(it >= 2) }
            click(compose.onAllNodes(androidx.compose.ui.test.hasText(string(R.string.protect_encrypt)) and androidx.compose.ui.test.hasClickAction())[1])
            awaitText(string(R.string.protect_saved))
            drawAll()
            clickText(string(R.string.action_save_as))
            answerPicker(scenario, Uri.fromFile(File(app.filesDir, "exported.p7m")))
            compose.waitUntil(10_000) { File(app.filesDir, "exported.p7m").length() > 0 }
            clickText(string(R.string.action_close))
            assertTrue(app.container.activity.entries.value.any { it.protectionOperation == "encrypt" })
        }
    }

    @Test fun consentFromABrowserRequestUsesTheSameSheet() {
        launch(capture = false).use {
            val worker = Thread {
                val answer = app.container.consentBroker.obtain(md.moldsign.core.ConsentRequest("https://msign.gov.md",
                    listOf("cerere.pdf"), "PAdES-T", signing.certificate, attemptsLeft = 1), 20_000)
                if (answer is ConsentResult.Pin) answer.pin.fill('\u0000')
            }
            worker.start()
            compose.mainClock.autoAdvance = false
            compose.waitUntil(10_000) { app.container.consentBroker.pending.value != null }
            compose.mainClock.advanceTimeBy(500)
            drawAll()
            assertEquals("https://msign.gov.md", app.container.consentBroker.pending.value!!.request.requester)
            clickTag("pin.cancel")
            compose.mainClock.autoAdvance = true
            worker.join(10_000)
            assertFalse(worker.isAlive)
        }
    }

    /** Opens the menu of the only document row (the toolbar has its own "more" menu with the tools). */
    private fun openRowMenu() {
        val more = compose.onAllNodes(androidx.compose.ui.test.hasContentDescription(string(R.string.action_more)))
        for (index in 0 until more.fetchSemanticsNodes().size) {
            click(more[index])
            if (shows(string(R.string.action_open))) return
            clickMenuItem(string(R.string.protect_title))
            clickText(string(R.string.action_cancel))
        }
        throw AssertionError("no document row menu: ${dump()}")
    }

    @Test fun savedDocumentMenusDetailsAndDeletion() {
        val store = md.moldsign.app.infrastructure.ProtectedFileStore(app)
        val signed = store.save("contract-semnat.pdf", "%PDF-1.7\n%%EOF\n".toByteArray())
        app.container.activity.document("contract-semnat.pdf", signed, ok = true, subtitle = "Signed · PAdES-T", signedOutput = true)
        launch(capture = false).use { scenario ->
            navigate("activity")
            awaitText("contract-semnat.pdf")
            drawAll()
            openRowMenu()
            drawAll()
            clickMenuItem(string(R.string.action_open))
            openRowMenu()
            clickMenuItem(string(R.string.action_save_as))
            answerPicker(scenario, Uri.fromFile(File(app.filesDir, "copy.pdf")))
            compose.waitUntil(10_000) { File(app.filesDir, "copy.pdf").length() > 0 }
            openRowMenu()
            clickMenuItem(string(R.string.protect_title))
            awaitText(string(R.string.protect_title))
            drawAll()
            clickText(string(R.string.action_cancel))
            // The details sheet verifies the saved file again.
            clickText("contract-semnat.pdf")
            awaitText(string(R.string.saved_details))
            runCatching { compose.waitUntil(15_000) { !shows(string(R.string.saved_loading)) } }
            drawAll()
            clickText(string(R.string.action_close))
            openRowMenu()
            clickMenuItem(string(R.string.nav_verify))
            awaitText(string(R.string.verdict_valid))
            navigate("activity")
            openRowMenu()
            clickMenuItem(string(R.string.saved_delete))
            awaitText(string(R.string.saved_delete_warning))
            drawAll()
            clickText(string(R.string.action_cancel))
            assertEquals(1, app.container.activity.signedDocuments.value.size)
        }
    }

    @Test fun encryptedDocumentOffersDecryption() {
        val encrypted = md.moldsign.app.infrastructure.ProtectedFileStore(app).save("notes.txt.symmetric.p7m", "x".toByteArray())
        app.container.activity.document("notes.txt.symmetric.p7m", encrypted, ok = true, subtitle = "Encrypted", protectionOperation = "encrypt")
        launch(capture = false).use {
            navigate("activity")
            awaitText("notes.txt.symmetric.p7m")
            openRowMenu()
            clickMenuItem(string(R.string.protect_decrypt))
            awaitText(string(R.string.protect_title))
            drawAll()
            clickText(string(R.string.action_cancel))
            clickText("notes.txt.symmetric.p7m")
            drawAll()
            clickTag("documents.deleteAll")
            drawAll()
            clickText(string(R.string.action_cancel))
        }
    }

    @Test fun batchAndFileOptionsMenus() {
        launch(capture = false).use { scenario ->
            clickTag("sign.method")
            clickTag("sign.reader")
            clickTag("sign.pickFiles")
            answerPicker(scenario, file("one.pdf", "%PDF-1.7\n%%EOF\n"), file("two.pdf", "%PDF-1.7\n%%EOF\n"), file("three.txt", "t"))
            awaitTag("sign.submit")
            clickDescription(string(R.string.batch_options))
            drawAll()
            clickText(string(R.string.format_xml))
            clickDescription(string(R.string.batch_options))
            clickText(string(R.string.batch_automatic))
            compose.waitForIdle()
            val files = string(R.string.batch_files)
            if (shows(files)) clickText(files)
            drawAll()
            if (shows(string(R.string.file_options))) {
                clickDescription(string(R.string.file_options))
                drawAll()
                clickText(string(R.string.file_remove))
            }
            clickTag("sign.addFiles")
            answerPicker(scenario, file("four.pdf", "%PDF-1.7\n%%EOF\n"))
            clickDescription(string(R.string.batch_options))
            clickText(string(R.string.batch_stamp))
            awaitText(string(R.string.stamp_title))
            drawAll()
            if (shows(string(R.string.stamp_next_page))) runCatching { clickDescription(string(R.string.stamp_next_page)) }
            clickText(string(R.string.action_cancel))
            clickDescription(string(R.string.batch_options))
            clickText(string(R.string.batch_remove))
            compose.waitUntil(5_000) { showsTag("sign.pickFiles") }
        }
    }
}
