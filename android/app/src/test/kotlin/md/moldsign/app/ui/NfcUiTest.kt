package md.moldsign.app.ui

import android.net.Uri
import android.nfc.NfcAdapter
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.performTextReplacement
import androidx.lifecycle.Lifecycle
import md.moldsign.app.R
import md.moldsign.app.application.AppContainer
import md.moldsign.app.pin.SavedCardIdentities
import md.moldsign.app.nfc.AndroidNfcRadio
import md.moldsign.app.nfc.NfcSigningController
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.testing.FakeMediaStore
import md.moldsign.app.testing.FakeReaderGateway
import md.moldsign.app.testing.FakeSigningService
import md.moldsign.core.CertificateSummary
import md.moldsign.core.ChainCerts
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowNfcAdapter
import java.io.File

/**
 * An NFC phone through the real Android radio adapter (Robolectric's NfcAdapter): reader mode around the PIN
 * sheet and the scan dialog, and the user-reported fix — after a card was seen, reader mode stays on until
 * the activity pauses instead of handing the card back to the system dispatcher.
 */
class NfcUiTest : AppUiTest() {
    private val identity = CertificateSummary.parse(ChainCerts.chain.first())
    private lateinit var adapter: ShadowNfcAdapter

    @Before fun nfcPhone() {
        ShadowNfcAdapter.setNfcHardwareExists(true)
        shadowOf(app.packageManager).setSystemFeature(android.content.pm.PackageManager.FEATURE_NFC, true)
        // The application's NfcManager was created before this test enabled NFC hardware: ask the adapter afresh.
        val nfcAdapter = NfcAdapter::class.java.getDeclaredMethod("getNfcAdapter", android.content.Context::class.java)
            .apply { isAccessible = true }.invoke(null, app) as NfcAdapter
        adapter = shadowOf(nfcAdapter)
        adapter.setEnabled(true)
        FakeMediaStore.install()
        SavedCardIdentities(app).save(identity)
        installContainer(AppContainer(app, signingFactory = { FakeSigningService() }, readerFactory = { _, _ -> FakeReaderGateway() },
            nfcFactory = { NfcSigningController(AndroidNfcRadio(nfcAdapter), it) }))
    }

    @After fun noNfc() = ShadowNfcAdapter.setNfcHardwareExists(false)

    private fun vm(scenario: androidx.test.core.app.ActivityScenario<md.moldsign.app.MainActivity>): MainViewModel {
        var vm: MainViewModel? = null
        scenario.onActivity { vm = androidx.lifecycle.ViewModelProvider(it)[MainViewModel::class.java] }
        return vm!!
    }

    private fun queueAndEnterPin(scenario: androidx.test.core.app.ActivityScenario<md.moldsign.app.MainActivity>) {
        clickTag("sign.pickFiles")
        answerPicker(scenario, Uri.fromFile(File(app.filesDir, "nfc.pdf").apply { writeText("%PDF-1.7\n%%EOF\n") }))
        until("the queued document") { showsTag("sign.submit") }
        clickTag("sign.submit")
        // The PIN is asked for on the signing worker; its request reaches the sheet through the main thread.
        until("the PIN sheet") { app.container.consentBroker.pending.value != null && showsTag("pin.field") }
        settle()
        drawAll()
        tag("pin.field").performTextReplacement("1234")
        settle()
        until("an enabled PIN confirmation") { runCatching { tag("pin.confirm").assertIsEnabled() }.isSuccess }
        clickTag("pin.confirm")
        // The worker opens the session, then posts reader-mode activation to the main thread.
        until("reader mode for the scan", { nfcState(scenario) }) { app.container.nfc.phase.value != null && adapter.isInReaderMode }
        settle()
    }

    /** What the session did, for a failure message. */
    private fun nfcState(scenario: androidx.test.core.app.ActivityScenario<md.moldsign.app.MainActivity>) =
        "phase=${app.container.nfc.phase.value} readerMode=${adapter.isInReaderMode} busy=${app.container.busy.value} " +
            "message=${vm(scenario).message.value}"

    @Test fun unsupportedCardKeepsReaderModeUntilPause() {
        compose.mainClock.autoAdvance = false
        launch(capture = false).use { scenario ->
            assertTrue(vm(scenario).nfcAvailable)
            assertEquals(MainViewModel.SigningMethod.NFC, vm(scenario).signingMethod.value)
            assertEquals(listOf(identity.sha1Hex), vm(scenario).knownCards.value.map { it.sha1Hex })
            drawAll()
            queueAndEnterPin(scenario)
            // The scan dialog is up and the antenna is in reader mode.
            assertTrue(adapter.isInReaderMode)
            assertTrue(shows(string(R.string.nfc_scan_hold)))
            drawAll()

            // The reader-mode callback runs the card check on the waiting worker; its failure ends the scan.
            adapter.dispatchTagDiscovered(ShadowNfcAdapter.createMockTag())
            until("the unsupported-card result", { nfcState(scenario) }) {
                app.container.nfc.phase.value == null && !app.container.busy.value && shows(string(R.string.nfc_unsupported))
            }
            drawAll()
            // The card that was seen may still be on the phone: reader mode is held, nothing goes to the system.
            assertTrue(adapter.isInReaderMode)
            assertEquals(null, app.container.nfc.phase.value)

            scenario.moveToState(Lifecycle.State.STARTED)
            assertFalse(adapter.isInReaderMode)
            scenario.moveToState(Lifecycle.State.RESUMED)
        }
    }

    @Test fun cancellingTheScanReleasesReaderModeAtOnce() {
        compose.mainClock.autoAdvance = false
        launch(capture = false).use { scenario ->
            queueAndEnterPin(scenario)
            assertTrue(adapter.isInReaderMode)
            clickText(string(R.string.action_cancel))
            until("the cancelled scan") { app.container.nfc.phase.value == null && !app.container.busy.value }
            assertFalse(adapter.isInReaderMode)
            // The queued document stays for an explicit new attempt; nothing was retried.
            assertTrue(showsTag("sign.submit"))
        }
    }

    @Test fun knownCardChoiceSavedCardsAndBrowserIdentity() {
        launch(capture = false).use { scenario ->
            clickTag("sign.pickFiles")
            answerPicker(scenario, Uri.fromFile(File(app.filesDir, "doc.pdf").apply { writeText("%PDF-1.7\n%%EOF\n") }))
            awaitTag("nfc.card")
            clickTag("nfc.card")
            drawAll()
            clickTag("nfc.another")
            assertEquals(null, vm(scenario).nfcIdentity.value)
            clickTag("nfc.card")
            clickText(identity.commonName)
            assertEquals(identity.sha1Hex, vm(scenario).nfcIdentity.value?.sha1Hex)
            clickTag("sign.cardDetails")
            awaitTag("settings.close")
            drawAll()
            clickTag("settings.close")

            navigate("browser")
            clickTag("browser.authentication")
            awaitTag("browser.card.${identity.sha1Hex}")
            drawAll()
            clickTag("browser.card.${identity.sha1Hex}")
            assertEquals(identity.sha1Hex, app.container.browserNfc.certificate.value?.sha1Hex)
            clickTag("browser.readNfc")
            until("reader mode for the browser card") { adapter.isInReaderMode && app.container.nfc.phase.value != null }
            adapter.dispatchTagDiscovered(ShadowNfcAdapter.createMockTag())
            until("the unsupported-card message") { shows(string(R.string.nfc_unsupported)) }

            navigate("settings")
            clickTag("card.savedPins")
            awaitText(string(R.string.card_forget))
            drawAll()
            clickText(string(R.string.card_forget))
            click(compose.onAllNodes(androidx.compose.ui.test.hasText(string(R.string.card_forget)) and androidx.compose.ui.test.hasClickAction())[1])
            until("the forgotten card") { vm(scenario).knownCards.value.isEmpty() }
            assertTrue(SavedCardIdentities(app).read().isEmpty())
        }
    }
}
