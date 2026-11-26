package md.moldsign.app.ui

import android.content.Context
import android.content.Intent
import androidx.compose.ui.test.SemanticsNodeInteraction
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Looper
import org.robolectric.Shadows.shadowOf
import androidx.compose.ui.platform.ViewRootForTest
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsNode
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isRoot
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import md.moldsign.app.MainActivity
import md.moldsign.app.MoldSignApp
import md.moldsign.app.testing.ShadowPdfDocument
import md.moldsign.app.testing.resetStaticAndroidState
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * The real app on Robolectric: MoldSignApp, MainActivity and every Compose screen, drawn with native graphics
 * so that canvas code runs too. Debug demo extras provide the fictional cards and documents; nothing here
 * touches USB, NFC or a PIN.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w411dp-h891dp", shadows = [ShadowPdfDocument::class])
abstract class AppUiTest {
    @get:Rule val compose = createEmptyComposeRule()
    protected val app: MoldSignApp get() = ApplicationProvider.getApplicationContext()
    private val scenarios = mutableListOf<ActivityScenario<MainActivity>>()

    protected fun string(id: Int, vararg args: Any): String = app.getString(id, *args)

    @Before fun acknowledgeDisclosure() {
        resetStaticAndroidState()
        // AppCompat keeps the per-app language statically across Robolectric tests.
        androidx.appcompat.app.AppCompatDelegate.setApplicationLocales(androidx.core.os.LocaleListCompat.getEmptyLocaleList())
        app.getSharedPreferences("public_information", Context.MODE_PRIVATE).edit().putBoolean("independence_notice_v1", true).commit()
    }

    @After fun closeEverything() {
        scenarios.forEach { runCatching { it.close() } }
        runCatching { app.container.stop() }
    }

    /** Launches MainActivity; [scenario] is a debug DemoMode fixture, [capture] the screenshot (store) variant. */
    protected fun launch(scenario: String? = null, page: String? = null, capture: Boolean = true,
                         extras: Intent.() -> Unit = {}): ActivityScenario<MainActivity> = start(scenario, page, capture, extras, track = true)

    /**
     * For theme/language changes: AppCompat recreates the activity, which ActivityScenario.close() then waits on.
     * Robolectric tears the activity down with the test instead.
     */
    protected fun launchRecreatable(scenario: String? = null, page: String? = null): ActivityScenario<MainActivity> =
        start(scenario, page, capture = true, extras = {}, track = false)

    private fun start(scenario: String?, page: String?, capture: Boolean, extras: Intent.() -> Unit, track: Boolean): ActivityScenario<MainActivity> {
        val intent = Intent(app, MainActivity::class.java)
        if (scenario != null) intent.putExtra("demo", scenario)
        if (page != null) intent.putExtra("demo_page", page)
        if (capture) intent.putExtra("store_capture", true)
        intent.extras()
        return ActivityScenario.launch<MainActivity>(intent).also { if (track) scenarios += it; compose.waitForIdle() }
    }

    /** Draws every window (activity, dialogs, sheets) into a bitmap: runs layout and canvas code. */
    protected fun drawAll() {
        compose.waitForIdle()
        compose.runOnIdle {
            compose.onAllNodes(isRoot()).fetchSemanticsNodes().map { (it.root as ViewRootForTest).view.rootView }.distinct().forEach { view ->
                if (view.width > 0 && view.height > 0) {
                    val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
                    view.draw(Canvas(bitmap))
                    bitmap.recycle()
                }
            }
        }
        compose.waitForIdle()
    }

    protected fun shows(text: String, substring: Boolean = true): Boolean =
        compose.onAllNodesWithText(text, substring = substring, useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty()

    protected fun showsDescription(text: String): Boolean =
        compose.onAllNodesWithContentDescription(text, substring = true, useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty()

    /** Every text, description and tag on screen, for diagnosing a failed expectation. */
    protected fun dump(): String = compose.onAllNodes(isRoot()).fetchSemanticsNodes().joinToString("\n---\n") { root ->
        val out = mutableListOf<String>()
        fun walk(node: SemanticsNode) {
            node.config.getOrNull(SemanticsProperties.Text)?.let { out += it.joinToString() }
            node.config.getOrNull(SemanticsProperties.ContentDescription)?.let { out += "[" + it.joinToString() + "]" }
            node.config.getOrNull(SemanticsProperties.TestTag)?.let { out += "#$it" }
            node.children.forEach(::walk)
        }
        walk(root)
        out.joinToString(" | ")
    }

    protected fun showsTag(tag: String): Boolean = compose.onAllNodesWithTag(tag, useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty()

    /** Also produces frames when a test drives the clock by hand. */
    /**
     * One deterministic step: run what other threads posted to the main thread (StateFlow collection, reader-mode
     * activation, dialogs), then one Compose frame when the test drives the clock by hand.
     */
    private fun frame() {
        shadowOf(Looper.getMainLooper()).idle()
        if (!compose.mainClock.autoAdvance) compose.mainClock.advanceTimeByFrame()
        shadowOf(Looper.getMainLooper()).idle()
    }

    /** Runs posted main-thread work and [millis] of Compose frames (manual clock) or until idle. */
    protected fun settle(millis: Long = 500) {
        shadowOf(Looper.getMainLooper()).idle()
        if (compose.mainClock.autoAdvance) compose.waitForIdle() else compose.mainClock.advanceTimeBy(millis)
        shadowOf(Looper.getMainLooper()).idle()
    }

    /**
     * Waits for work on another thread (signing and IO workers): every step drains the main looper and renders a
     * frame, so the outcome never depends on timing. The limit only stops a broken run; it reports the screen.
     */
    protected fun until(what: String, detail: () -> String = { "" }, condition: () -> Boolean) {
        val deadline = System.nanoTime() + 120_000_000_000L
        while (true) {
            frame()
            if (compose.mainClock.autoAdvance) compose.waitForIdle()
            if (condition()) return
            if (System.nanoTime() > deadline) throw AssertionError("$what did not happen. ${detail()} On screen: ${dump()}")
            Thread.sleep(2)
        }
    }

    protected fun awaitText(text: String, timeoutMs: Long = 30_000) {
        try { compose.waitUntil(timeoutMs) { frame(); shows(text) || showsDescription(text) } }
        catch (error: Throwable) { throw AssertionError("'$text' not shown in: ${dump()}", error) }
    }

    protected fun awaitTag(tag: String, timeoutMs: Long = 30_000) {
        try { compose.waitUntil(timeoutMs) { frame(); showsTag(tag) } }
        catch (error: Throwable) { throw AssertionError("#$tag not shown in: ${dump()}", error) }
    }

    /** The first node showing [text], preferring one that can be clicked (a button over its own caption). */
    protected fun text(text: String): SemanticsNodeInteraction {
        val clickable = compose.onAllNodes(hasText(text, substring = true) and hasClickAction())
        if (clickable.fetchSemanticsNodes().isNotEmpty()) return clickable.onFirst()
        return compose.onAllNodes(hasText(text, substring = true)).onFirst()
    }
    protected fun tag(tag: String): SemanticsNodeInteraction = compose.onAllNodes(hasTestTag(tag)).onFirst()

    protected fun clickText(text: String) = click(text(text))

    /** An item of the open dropdown menu (not a same-named button behind it). */
    protected fun clickMenuItem(text: String) =
        click(compose.onAllNodes(hasText(text) and hasClickAction() and androidx.compose.ui.test.hasAnyAncestor(androidx.compose.ui.test.isPopup())).onFirst())
    protected fun clickTag(tag: String) = click(tag(tag))
    protected fun clickDescription(text: String) =
        click(compose.onAllNodes(hasContentDescription(text, substring = true)).onFirst())

    /** Semantic click (what TalkBack does); touch injection is unreliable for rows inside scrolling sheets. */
    protected fun click(node: SemanticsNodeInteraction) {
        try { node.assertExists() } catch (error: AssertionError) { throw AssertionError("${error.message}\nOn screen: ${dump()}", error) }
        runCatching { node.performScrollTo() }
        if (SemanticsActions.OnClick in node.fetchSemanticsNode().config) node.performSemanticsAction(SemanticsActions.OnClick)
        else node.performClick()
        if (!compose.mainClock.autoAdvance) settle(300)
        compose.waitForIdle()
    }

    protected fun navigate(destination: String) = clickTag("nav.$destination")

    /** Replaces the application graph (e.g. fake card adapters in real, non-demo mode) before an activity starts. */
    protected fun installContainer(container: md.moldsign.app.application.AppContainer) {
        val old = app.container
        MoldSignApp::class.java.getDeclaredField("container").apply { isAccessible = true }.set(app, container)
        old.stop()
        container.start()
    }

    /** Answers the system picker or save dialog the screen just opened, as the user would. */
    protected fun answerPicker(scenario: ActivityScenario<MainActivity>, vararg uris: android.net.Uri, cancel: Boolean = false) {
        scenario.onActivity { activity ->
            val shadow = org.robolectric.Shadows.shadowOf(activity)
            val request = requireNotNull(shadow.nextStartedActivityForResult) { "no picker was opened" }
            val data = android.content.Intent()
            if (uris.size == 1) data.data = uris.single()
            else if (uris.isNotEmpty()) data.clipData = android.content.ClipData.newRawUri("", uris.first()).apply { uris.drop(1).forEach { addItem(android.content.ClipData.Item(it)) } }
            shadow.receiveResult(request.intent, if (cancel) android.app.Activity.RESULT_CANCELED else android.app.Activity.RESULT_OK, data)
        }
        compose.waitForIdle()
    }
}
