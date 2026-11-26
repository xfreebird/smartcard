package md.moldsign.app.ui

import md.moldsign.app.R
import md.moldsign.core.ReaderSlot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.performClick

/** Every destination in each fictional wallet/document state, as the screenshot fixtures show them. */
class DemoScenarioScreensTest : AppUiTest() {
    private val destinations = listOf("verify", "activity", "browser", "settings", "sign")

    private fun visitAll() {
        drawAll()
        destinations.forEach { navigate(it); drawAll() }
    }

    @Test fun twoReadyCardsOnEveryDestination() {
        launch("cards", "sign")
        assertEquals(2, app.container.wallet.value.readyCards.size)
        assertTrue(shows(string(R.string.app_name)))
        visitAll()
        // The Browser status chip opens Settings.
        navigate("browser")
        assertTrue(showsTag("navigation.title"))
    }

    @Test fun readerStatesAreExplainedInTheCardSheet() {
        for ((scenario, expected) in listOf(
            "noreader" to string(R.string.wallet_connect_title),
            "empty" to string(R.string.wallet_insert_title),
            "permission" to string(R.string.usb_permission_title),
        )) {
            launch(scenario, "card").use {
                clickTag("settings.card")
                drawAll()
                clickText(string(R.string.guided_method_caption))
                clickText(string(R.string.guided_reader))
                drawAll()
                awaitText(expected)
                assertNull(app.container.consentBroker.pending.value)
            }
        }
    }

    @Test fun readingAndErrorCards() {
        launch("reading", "sign").use {
            val card = app.container.status.value.wallet.cards.single()
            assertTrue(card.isReading)
            visitAll()
        }
        launch("error", "sign").use {
            assertTrue(app.container.wallet.value.cards.any { it.problem != null })
            visitAll()
        }
        launch("one", "sign").use {
            assertEquals(1, app.container.wallet.value.readers.count { it.state == ReaderSlot.State.Card })
            visitAll()
        }
    }

    @Test fun verificationVerdicts() {
        for ((scenario, verdict) in listOf(
            "verify-valid" to R.string.verdict_valid,
            "verify-invalid" to R.string.verdict_invalid,
            "verify-unconfirmed" to R.string.verdict_unconfirmed,
            "verify-none" to R.string.verdict_none,
            "verify-xml-missing" to R.string.verdict_unconfirmed,
            "verify-xml-complete" to R.string.verdict_valid,
            "verify-review" to R.string.verdict_valid,
        )) {
            launch(scenario, "verify").use {
                awaitText(string(verdict))
                drawAll()
                clickTag("verify.clearResults")
                assertFalse(shows(string(verdict)))
                assertTrue(showsTag("verify.pickFiles"))
            }
        }
    }

    @Test fun documentsBatchAndFailure() {
        for (scenario in listOf("documents", "batch", "sign-failure")) {
            launch(scenario, "sign").use {
                compose.waitUntil(10_000) { app.container.status.value.wallet.readyCards.isNotEmpty() }
                drawAll()
                navigate("activity")
                drawAll()
                navigate("sign")
                drawAll()
            }
        }
    }

    @Test fun completedResultsCanBeHidden() {
        launch("results", "sign").use {
            val clear = string(R.string.results_clear)
            awaitText(clear)
            drawAll()
            compose.onAllNodesWithContentDescription(clear).onFirst().performClick()
            compose.waitForIdle()
            assertFalse(showsDescription(clear))
            assertNull(app.container.consentBroker.pending.value)
        }
    }

    @Test fun activityHistoryStates() {
        launch("history-review", "activity").use { drawAll() }
        launch("activity-empty", "activity").use { drawAll() }
    }

    @Test fun fictionalPinRequestShowsTheSheet() {
        // The focused PIN field blinks its cursor forever: drive frames by hand.
        compose.mainClock.autoAdvance = false
        launch("pin", "sign").use {
            compose.waitUntil(10_000) { app.container.consentBroker.pending.value != null }
            compose.mainClock.advanceTimeBy(1_000)
            drawAll()
            assertTrue(showsTag("pin.dialog"))
        }
        launch("pin-warning", "sign").use {
            compose.waitUntil(10_000) { app.container.consentBroker.pending.value?.request?.attemptsLeft == 2 }
            compose.mainClock.advanceTimeBy(1_000)
            drawAll()
            awaitText(string(R.string.pin_attempts, 2))
        }
    }
}
