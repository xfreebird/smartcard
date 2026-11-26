package md.moldsign.app.ui

import android.graphics.Bitmap
import android.graphics.Canvas
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.test.core.app.ApplicationProvider
import md.moldsign.app.MoldSignApp
import md.moldsign.app.R
import md.moldsign.app.application.VerifyOutcome
import md.moldsign.app.testing.resetStaticAndroidState
import md.moldsign.app.testing.testCertificate
import md.moldsign.app.ui.components.EmptyWalletContent
import md.moldsign.app.ui.components.IdCardFace
import md.moldsign.app.ui.components.IdentityCardContent
import md.moldsign.app.ui.components.CardWallet
import md.moldsign.app.ui.components.CardWalletContent
import md.moldsign.app.ui.components.StatusContent
import md.moldsign.app.ui.components.StatusDot
import md.moldsign.app.ui.components.StatusLightChip
import md.moldsign.app.ui.screens.CardDetails
import md.moldsign.app.ui.screens.MissingDocuments
import md.moldsign.app.ui.screens.SignatureCard
import md.moldsign.app.ui.screens.VerdictBadge
import md.moldsign.app.ui.theme.MoldSignTheme
import md.moldsign.app.ui.theme.StatusTone
import md.moldsign.core.CardError
import md.moldsign.core.ValidationReport
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.util.Date

/** Components in states the fixtures do not reach: every verdict, problem cards, empty wallets, status tones. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w411dp-h891dp")
class ComponentsUiTest {
    @get:Rule val compose = createEmptyComposeRule()
    private val app = ApplicationProvider.getApplicationContext<MoldSignApp>()

    @Before fun reset() {
        resetStaticAndroidState()
        // Reading cards and the busy light pulse forever: frames are advanced by hand.
        compose.mainClock.autoAdvance = false
    }

    private fun show(dark: Boolean = false, content: @Composable () -> Unit) {
        val activity = Robolectric.buildActivity(ComponentActivity::class.java).setup().get()
        activity.setContent { MoldSignTheme(darkTheme = dark) { Column(Modifier.verticalScroll(rememberScrollState())) { content() } } }
        compose.mainClock.advanceTimeBy(500)
        compose.waitForIdle()
        val view = activity.window.decorView
        val bitmap = Bitmap.createBitmap(maxOf(1, view.width), maxOf(1, view.height), Bitmap.Config.ARGB_8888)
        view.draw(Canvas(bitmap))
        bitmap.recycle()
    }

    private fun shows(text: String) = compose.onAllNodesWithText(text, substring = true, useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty()

    private val report = ValidationReport("ION POPESCU", Date(1_793_081_400_000L), Date(1_793_081_400_000L), "PAdES-B-T",
        integrityOk = true, signatureOk = true, chainOk = true, details = listOf("Offline verification"),
        certificateDetails = linkedMapOf("Subject · Name" to "ION POPESCU", "Subject · Personal identifier" to "2001234567890"))

    @Test fun everyVerdictAndSignatureCard() {
        for (dark in listOf(false, true)) show(dark) {
            VerdictBadge(VerifyOutcome(listOf(report)))
            VerdictBadge(VerifyOutcome(listOf(report.copy(integrityOk = false))))
            VerdictBadge(VerifyOutcome(listOf(report.copy(chainOk = false))))
            VerdictBadge(VerifyOutcome(listOf(report.copy(chainOk = null, missingDocuments = listOf("a.txt")))))
            VerdictBadge(VerifyOutcome(emptyList()))
            SignatureCard(report)
            SignatureCard(report.copy(signerName = null, signingTime = null, timestampTime = null, level = null, chainOk = null, signatureOk = false))
            MissingDocuments(listOf("a.txt", "b.txt")) {}
        }
        for (verdict in listOf(R.string.verdict_valid, R.string.verdict_invalid, R.string.verdict_unconfirmed, R.string.verdict_none))
            assertTrue(shows(app.getString(verdict)))
    }

    @Test fun cardFacesAndWallets() {
        val ready = IdentityCardContent("r1", "miniLector EVO", "ION POPESCU", "POPESCU", "ION", "15 03 2030", "MDQSign", true, null, 6f, "Ready card")
        val reading = ready.copy(readerId = "r2", hasIdentity = false, surname = "", givenNames = "")
        val problem = ready.copy(readerId = "r3", problem = "Remove and insert the card", description = "Problem")
        show {
            IdCardFace(ready)
            IdCardFace(ready, usedForSigning = true, reserveDisclosure = true, showReader = false)
            IdCardFace(reading)
            IdCardFace(problem)
            CardWallet(CardWalletContent(listOf(ready, reading, problem), "r2", EmptyWalletContent.Connect), {}, {}, {}, large = true)
            for (empty in listOf(EmptyWalletContent.Connect, EmptyWalletContent.Permission("r1", "miniLector"), EmptyWalletContent.Insert("miniLector"),
                EmptyWalletContent.Error("miniLector"))) CardWallet(CardWalletContent(emptyList(), null, empty), {}, {}, {})
        }
        assertTrue(shows(app.getString(R.string.usb_permission_title)))
    }

    @Test fun statusChipsAndCardDetails() {
        show(dark = true) {
            StatusTone.entries.forEach { tone ->
                StatusLightChip(StatusContent("Label $tone", "Description", tone), onClick = {})
                StatusLightChip(StatusContent("Compact $tone", "Description", tone), onClick = {}, compact = true)
                StatusDot(tone)
            }
            CardDetails(testCertificate(der = null), problem = null, readerName = "miniLector EVO")
            CardDetails(null, problem = CardError.CardStateStuck(), readerName = "miniLector EVO")
        }
        assertEquals(true, shows("Label ${StatusTone.Success}"))
        assertTrue(shows("TEST HOLDER"))
    }

    @Test fun bookmarkDialogs() {
        val bookmarks = listOf(
            md.moldsign.app.application.BrowserBookmark("builtin:https://msign.gov.md/", "MSign", "https://msign.gov.md/", md.moldsign.app.application.BookmarkIcon.Document),
            md.moldsign.app.application.BrowserBookmark("custom:1", "Library", "https://example.md/", md.moldsign.app.application.BookmarkIcon.Star),
        )
        show { md.moldsign.app.ui.screens.ManageBookmarksDialog(bookmarks, onDismiss = {}, onEdit = {}, onRemove = {}) }
        assertTrue(shows("Library"))
        show { md.moldsign.app.ui.screens.ManageBookmarksDialog(emptyList(), onDismiss = {}, onEdit = {}, onRemove = {}) }
        md.moldsign.app.application.BookmarkIcon.entries.forEach { icon ->
            show { md.moldsign.app.ui.screens.BookmarkImage(bookmarks[1].copy(icon = icon)) }
        }
    }
}
