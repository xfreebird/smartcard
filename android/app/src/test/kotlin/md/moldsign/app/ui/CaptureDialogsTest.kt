package md.moldsign.app.ui

import md.moldsign.app.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** The dialogs, sheets and menus of the store screenshot fixtures, each drawn in its own state. */
class CaptureDialogsTest : AppUiTest() {
    private fun capture(scenario: String, page: String, dialog: String? = null, expand: String? = null, step: String? = null) =
        launch(scenario, page) {
            dialog?.let { putExtra("capture_dialog", it) }
            expand?.let { putExtra("capture_expand", it) }
            step?.let { putExtra("capture_step", it) }
        }

    @Test fun disclosureSettingsAboutAndDemoConfirmation() {
        capture("cards", "sign", "disclosure").use {
            awaitText(string(R.string.government_independence_title))
            drawAll()
            clickText(string(R.string.government_notice_continue))
        }
        capture("cards", "settings", "settings").use {
            awaitTag("settings.screen")
            drawAll()
        }
        capture("cards", "settings", "about").use {
            awaitText(string(R.string.about_title))
            drawAll()
        }
        capture("cards", "sign", "demo-confirm").use {
            awaitText(string(R.string.demo_mode_enable))
            drawAll()
            clickText(string(R.string.action_cancel))
            assertTrue(!shows(string(R.string.demo_mode_enable)))
        }
    }

    @Test fun fileProtectionStates() {
        capture("cards", "activity", "protect-menu").use {
            drawAll()
            awaitText(string(R.string.protect_title))
        }
        for (dialog in listOf("protect-encrypt", "protect-decrypt", "protect-certificate-encrypt", "protect-certificate-decrypt",
            "protect-encrypt-complete", "protect-decrypt-complete")) {
            capture("cards", "activity", dialog).use {
                awaitText(string(R.string.protect_title))
                if (dialog.endsWith("complete")) awaitText(string(R.string.protect_saved))
                drawAll()
            }
        }
    }

    @Test fun historyAndDocumentDetails() {
        capture("cards", "activity", "history").use { awaitTag("documents.clearHistory"); drawAll() }
        capture("cards", "activity", "history-clear").use {
            awaitTag("documents.clearHistory.confirm")
            drawAll()
            clickTag("documents.clearHistory.confirm")
            compose.waitUntil(5_000) { app.container.activity.entries.value.isEmpty() }
        }
        capture("cards", "activity", "document-details").use { drawAll() }
        capture("cards", "activity", "document-missing").use { drawAll() }
    }

    @Test fun formatMenusAndSigningProgress() {
        capture("documents", "sign", "format-menu").use { drawAll() }
        capture("batch", "sign", "batch-menu").use { drawAll() }
        for (step in listOf("Connecting", "Authenticating", "Signing", "Timestamping")) {
            capture("batch", "sign", step = step).use { drawAll() }
        }
    }

    @Test fun verificationDisclosures() {
        capture("verify-valid", "verify", expand = "certificate").use { awaitText(string(R.string.verdict_valid)); drawAll() }
        capture("verify-valid", "verify", expand = "technical").use { awaitText(string(R.string.verdict_valid)); drawAll() }
        capture("verify-xml-missing", "verify").use { drawAll() }
    }

    @Test fun inAppBrowserWindow() {
        capture("cards", "browser", "browser-window").use { drawAll() }
    }

    @Test fun stampPlacementPreview() {
        launch("documents", "sign") { putExtra("stamp_preview", true) }.use {
            compose.waitUntil(10_000) { compose.onAllNodes(androidx.compose.ui.test.isRoot()).fetchSemanticsNodes().size > 1 }
            drawAll()
            assertEquals(1, app.container.wallet.value.cards.count { it.readerId == "demo-1" })
        }
    }
}
