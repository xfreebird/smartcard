package md.moldsign.app.ui

import androidx.lifecycle.ViewModelProvider
import md.moldsign.app.MainActivity
import md.moldsign.app.R
import md.moldsign.app.application.AppContainer
import md.moldsign.app.infrastructure.ActivityLog
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.presentation.UiMessage
import md.moldsign.app.testing.FakeDocumentAccess
import md.moldsign.app.testing.FakeMediaStore
import md.moldsign.app.testing.FakeReaderGateway
import md.moldsign.app.testing.FakeSigningService
import md.moldsign.app.testing.awaitMain
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Owner rule: demo-only UI (the demo banner, "not a valid signature" notices, DEMO file names, fictional
 * cards) appears only while demo mode is on, never in real NFC/reader signing, results, documents,
 * settings or notifications.
 */
class DemoIsolationTest : AppUiTest() {
    private val destinations = listOf("sign", "verify", "activity", "browser", "settings")
    private val demoNotices get() = listOf(
        string(R.string.demo_mode_disclaimer), string(R.string.demo_mode_result), string(R.string.demo_banner),
        string(R.string.demo_output_notice), string(R.string.demo_sign_success), string(R.string.demo_verify_success),
        "DEMO", "NOT-SIGNED", "NOT A VALID SIGNATURE",
    )

    @Before fun mediaStore() = FakeMediaStore.install()

    private fun assertNoDemoText(where: String) {
        val screen = dump()
        demoNotices.forEach { notice -> assertFalse("$where shows demo text '$notice': $screen", screen.contains(notice)) }
    }

    @Test fun realModeShowsNoDemoNoticeOnAnyDestination() {
        assertFalse(app.demoModeEnabled)
        launch(capture = false).use {
            assertFalse(app.container.isDemo)
            destinations.forEach { navigate(it); drawAll(); assertNoDemoText(it) }
            // The settings switch that enters demo mode is the only demo entry point, and it is off.
            assertTrue(shows(string(R.string.demo_mode_title)))
            assertFalse(viewModel(it).demoMode)
        }
    }

    @Test fun demoModeLabelsEveryDestinationAndItsOutputs() {
        assertTrue(app.changeDemoMode(true))
        launch(capture = false).use { scenario ->
            destinations.forEach { navigate(it); assertTrue("$it lacks the demo banner", shows(string(R.string.demo_mode_disclaimer))) }
            navigate("sign")
            val vm = viewModel(scenario)
            assertTrue(vm.signItems.value.all { it.doc.name.startsWith("DEMO-") })
            vm.sign()
            awaitMain(30_000) { !vm.working.value && vm.signedResults.value.isNotEmpty() }
            assertTrue(vm.signedResults.value.all { (name, _) -> name.startsWith("DEMO-") && name.endsWith("-NOT-SIGNED.pdf") })
            assertTrue(app.container.activity.entries.value.all { it.subtitle == string(R.string.demo_mode_result) })
            assertEquals(R.string.demo_mode_result, (vm.message.value as? UiMessage.Saved)?.res)
            // Demo outputs stay private: nothing joins the real signed documents in Downloads/eSemnBun.
            assertTrue(FakeMediaStore.names().isEmpty())
            assertTrue(vm.signedResults.value.all { (_, uri) -> uri.authority == "${app.packageName}.protected-files" })
        }
        // Leaving demo mode leaves none of its documents, history or notices behind.
        assertTrue(app.changeDemoMode(false))
        assertFalse(app.container.isDemo)
        assertTrue(app.container.activity.entries.value.isEmpty())
        assertTrue(app.container.activity.signedDocuments.value.isEmpty())
        launch(capture = false).use {
            destinations.forEach { navigate(it); drawAll(); assertNoDemoText("after demo: $it") }
        }
    }

    @Test fun realSigningUsesRealNamesAndNotices() {
        val signing = FakeSigningService()
        val readers = FakeReaderGateway()
        val container = AppContainer(app, signingFactory = { signing }, readerFactory = { _, _ -> readers })
        container.start()
        try {
            awaitMain { container.wallet.value.readyCards.isNotEmpty() }
            val documents = FakeDocumentAccess()
            val vm = MainViewModel(app, documents = documents, container = container)
            vm.selectSigningMethod(MainViewModel.SigningMethod.Reader)
            vm.addForSigning(listOf(documents.add("contract.pdf"), documents.add("note.txt", "note".toByteArray())))
            awaitMain { vm.signItems.value.size == 2 }
            vm.sign()
            awaitMain(30_000) { !vm.working.value && vm.signedResults.value.size == 2 }

            assertEquals(listOf("contract-semnat.pdf", "note-semnat.xml"), vm.signedResults.value.map { it.first })
            assertEquals(listOf("contract-semnat.pdf", "note-semnat.xml"), FakeMediaStore.names())
            assertTrue(FakeMediaStore.items.values.all { !it.pending && it.relativePath == "Download/eSemnBun" })
            val subtitles = container.activity.entries.value.map { it.subtitle }.toSet()
            assertEquals(setOf(string(R.string.activity_signed, "PAdES-T"), string(R.string.activity_signed, "XAdES-T")), subtitles)
            val saved = vm.message.value as UiMessage.Saved
            assertEquals(R.string.signed_saved, saved.res)
            assertNotNull(saved.uri)
            val visible = (vm.signedResults.value.map { it.first } + container.activity.entries.value.flatMap { listOf(it.title, it.subtitle) })
            visible.forEach { text -> demoNotices.forEach { assertFalse("'$text' contains '$it'", text.contains(it)) } }
            assertFalse(container.isDemo)
        } finally { container.stop() }
    }

    @Test fun screenshotFixturesNeverReplaceThePersistedHistory() {
        val real = ActivityLog(app, app.container.scope)
        real.browser("msign.gov.md", ok = true, subtitle = "real request")
        launch("cards", "activity").use {
            // The fixture is on screen for this process only.
            assertTrue(app.container.activity.entries.value.any { it.title == "contract-semnat.pdf" })
        }
        val reloaded = ActivityLog(app, app.container.scope)
        assertEquals(listOf("real request"), reloaded.entries.value.map { it.subtitle })
        assertTrue(reloaded.signedDocuments.value.isEmpty())
    }

    private fun viewModel(scenario: androidx.test.core.app.ActivityScenario<MainActivity>): MainViewModel {
        var vm: MainViewModel? = null
        scenario.onActivity { vm = ViewModelProvider(it)[MainViewModel::class.java] }
        return requireNotNull(vm)
    }
}
