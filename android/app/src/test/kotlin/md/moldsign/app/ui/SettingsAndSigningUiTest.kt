package md.moldsign.app.ui

import android.content.Context
import androidx.compose.ui.test.onAllNodesWithText
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Settings pages, the signing-method choices and the card sheets, driven like a user would. */
class SettingsAndSigningUiTest : AppUiTest() {
    @Test fun settingsPagesOpenAndClose() {
        launch("cards", "settings").use {
            for ((tag, title) in listOf("settings.card" to R.string.settings_card_reader, "card.savedPins" to R.string.pin_saved_title,
                "settings.help" to R.string.nfc_how_it_works, "settings.about" to R.string.about_title)) {
                clickTag(tag)
                awaitTag("settings.task")
                assertTrue(shows(string(title)))
                drawAll()
                clickTag("settings.close")
                compose.waitUntil(30_000) { !showsTag("settings.task") }
            }
        }
    }

    @Test fun appearanceAndDocumentPreferences() {
        launchRecreatable("cards", "settings").let { scenario ->
            // Switches: demo mode, recent documents in the widget, visible browser stamps.
            val switches = compose.onAllNodes(androidx.compose.ui.test.isToggleable())
            assertEquals(3, switches.fetchSemanticsNodes().size)
            click(switches[1])
            assertTrue(md.moldsign.app.widget.DocumentsWidget.showsRecents(app))
            click(switches[2])
            assertTrue(app.container.stampBroker.enabled)
            // Last: a new language recreates the activity in that language.
            clickText(string(R.string.settings_language))
            drawAll()
            clickText("Русский")
            compose.waitForIdle()
            assertEquals("ru", app.getSharedPreferences("settings", Context.MODE_PRIVATE).getString("widget_language", null))
            scenario.onActivity {
                it.changeAppLanguage("invalid")
                it.changeAppTheme("invalid")
                it.changeAppTheme("dark")
                assertEquals("dark", it.themePreference)
            }
        }
    }

    @Test fun darkThemeOnEveryDestination() {
        app.getSharedPreferences("settings", Context.MODE_PRIVATE).edit().putString("app_theme", "dark").commit()
        launch("cards", "sign").use {
            for (destination in listOf("sign", "verify", "activity", "browser", "settings")) { navigate(destination); drawAll() }
        }
    }

    @Test fun signingMethodMenuAndHelp() {
        launch("cards", "sign").use { scenario ->
            clickTag("sign.method")
            clickTag("sign.reader")
            scenario.onActivity { assertEquals(MainViewModel.SigningMethod.Reader, vm(it).signingMethod.value) }
            drawAll()
            clickTag("nfc.help.open")
            drawAll()
            clickText(string(R.string.action_close))
            clickTag("sign.method")
            clickTag("sign.nfc")
            scenario.onActivity { assertEquals(MainViewModel.SigningMethod.NFC, vm(it).signingMethod.value) }
            clickTag("nfc.help.open")
            awaitTag("nfc.help")
            drawAll()
            clickTag("nfc.help.close")
            clickTag("sign.cardDetails")
            drawAll()
        }
    }

    @Test fun readerCardsSheetAndCardDetails() {
        launch("cards", "settings").use { scenario ->
            clickTag("settings.card")
            awaitTag("settings.task")
            clickTag("sign.method")
            clickTag("sign.reader")
            drawAll()
            awaitTag("reader.cards")
            scenario.onActivity { vm(it).selectCard("demo-2") }
            compose.waitForIdle()
            assertEquals("demo-2", app.container.wallet.value.selectedCard?.readerId)
            drawAll()
            if (showsTag("card.details")) { clickTag("card.details"); drawAll() }
        }
        launch("documents", "sign").use { scenario ->
            scenario.onActivity { vm(it).selectSigningMethod(MainViewModel.SigningMethod.Reader) }
            compose.waitForIdle()
            drawAll()
            if (showsTag("signing.reader.cards")) { clickTag("signing.reader.cards"); drawAll() }
            clickTag("sign.cardDetails")
            drawAll()
            assertTrue(compose.onAllNodesWithText(app.container.wallet.value.selectedCard!!.certificate!!.commonName, substring = true).fetchSemanticsNodes().isNotEmpty())
        }
    }

    private fun vm(activity: md.moldsign.app.MainActivity) =
        androidx.lifecycle.ViewModelProvider(activity)[MainViewModel::class.java]
}
