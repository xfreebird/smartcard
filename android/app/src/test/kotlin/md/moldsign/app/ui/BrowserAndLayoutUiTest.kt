package md.moldsign.app.ui

import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.hasSetTextAction
import md.moldsign.app.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.robolectric.annotation.Config

/** The embedded browser chrome (bookmarks, data reset), browser authentication choices and the tablet layout. */
class BrowserAndLayoutUiTest : AppUiTest() {
    @Test fun inAppBrowserBookmarksAndDataReset() {
        launch("one", "browser") { putExtra("capture_dialog", "browser-window") }.use {
            awaitText(string(R.string.browser_services))
            drawAll()
            clickDescription(string(R.string.browser_services))
            drawAll()
            clickText(string(R.string.browser_bookmark_manage))
            awaitText(string(R.string.browser_bookmark_manage))
            drawAll()
            clickText(string(R.string.browser_close))
            clickDescription(string(R.string.browser_services))
            clickText(string(R.string.browser_clear_data))
            awaitText(string(R.string.browser_clear_selected))
            drawAll()
            clickText(string(R.string.action_cancel))
            clickDescription(string(R.string.browser_reload))
            clickDescription(string(R.string.browser_close))
            awaitText(string(R.string.browser_open_in_app))
        }
    }

    @Test fun browserAuthenticationChoicesAndBridgeSwitch() {
        launch("one", "browser").use {
            awaitTag("browser.authentication")
            drawAll()
            assertTrue(shows(string(R.string.bridge_toggle)))
            clickTag("browser.authentication")
            awaitTag("browser.method.reader")
            drawAll()
            clickTag("browser.method.reader")
            clickTag("browser.method.nfc")
            drawAll()
            clickText(string(R.string.action_close))
            clickText(string(R.string.government_sources_action))
            awaitText(string(R.string.government_independence_title))
            drawAll()
            clickText(string(R.string.government_notice_continue))
        }
    }

    @Test @Config(qualifiers = "w1280dp-h800dp")
    fun tabletUsesTheRailAndCentredTasks() {
        launch("cards", "sign").use {
            for (destination in listOf("verify", "activity", "browser", "settings", "sign")) { navigate(destination); drawAll() }
            navigate("settings")
            clickTag("settings.about")
            awaitTag("settings.task")
            drawAll()
            clickTag("settings.close")
        }
        launch("batch", "sign").use { drawAll() }
        launch("verify-valid", "verify").use { drawAll() }
    }

    @Test @Config(qualifiers = "w800dp-h360dp")
    fun shortLandscapePhone() {
        launch("documents", "sign").use {
            for (destination in listOf("verify", "activity", "browser", "settings", "sign")) { navigate(destination); drawAll() }
        }
        launch("pin", "sign").use {
            compose.mainClock.autoAdvance = false
            compose.waitUntil(30_000) { app.container.consentBroker.pending.value != null }
            compose.mainClock.advanceTimeBy(500)
            drawAll()
            assertEquals(3, app.container.consentBroker.pending.value!!.request.documentNames.size)
        }
    }
}
