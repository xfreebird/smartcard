package md.moldsign.app.ui

import android.app.NotificationManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbManager
import android.net.Uri
import androidx.lifecycle.ViewModelProvider
import kotlinx.coroutines.runBlocking
import md.moldsign.app.AppShortcuts
import md.moldsign.app.MainActivity
import md.moldsign.app.R
import md.moldsign.app.bridge.BridgeService
import md.moldsign.app.infrastructure.AndroidDocumentAccess
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.widget.DocumentsWidget
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.robolectric.Robolectric
import org.robolectric.Shadows.shadowOf
import java.io.File

/** Entry points around the screens: share/USB/shortcut intents, storage adapter, widget and bridge service. */
class AppShellTest : AppUiTest() {
    private fun vm(scenario: androidx.test.core.app.ActivityScenario<MainActivity>): MainViewModel {
        var vm: MainViewModel? = null
        scenario.onActivity { vm = ViewModelProvider(it)[MainViewModel::class.java] }
        return vm!!
    }

    /** MainActivity is singleTop: a new launch intent arrives through onNewIntent. */
    private fun deliver(activity: MainActivity, intent: Intent) {
        val launch = activity.intent
        MainActivity::class.java.getDeclaredMethod("onNewIntent", Intent::class.java).apply { isAccessible = true }.invoke(activity, intent)
        // ActivityScenario finds its activity by the launch intent; keep it so the scenario can close.
        activity.intent = launch
    }

    private fun localFile(name: String, body: String) = File(app.filesDir, name).apply { writeText(body) }

    @Test fun sharedDocumentsAreCopiedAndQueued() {
        val one = Uri.fromFile(localFile("shared-one.pdf", "%PDF-1.7\n%%EOF\n"))
        val two = Uri.fromFile(localFile("shared-two.txt", "text"))
        launch(capture = false) {
            action = Intent.ACTION_SEND_MULTIPLE
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, arrayListOf(one, two))
        }.use { scenario ->
            val vm = vm(scenario)
            compose.waitUntil(30_000) { vm.signItems.value.size == 2 }
            assertEquals(setOf("shared-one.pdf", "shared-two.txt"), vm.signItems.value.map { it.doc.name }.toSet())
            drawAll()
        }
    }

    @Test fun shortcutsUsbAttachAndWidgetDocument() {
        launch(capture = false) { action = UsbManager.ACTION_USB_DEVICE_ATTACHED }.use { scenario ->
            scenario.onActivity {
                deliver(it, Intent(app, MainActivity::class.java).setAction(AppShortcuts.ACTION))
            }
            compose.waitForIdle()
            assertTrue(shows(string(R.string.nav_activity)))
            scenario.onActivity {
                deliver(it, Intent(app, MainActivity::class.java).setAction(AppShortcuts.ACTION)
                    .putExtra(AppShortcuts.FEATURE, AppShortcuts.Destination.Verify.id))
            }
            compose.waitForIdle()
            // The verify shortcut opens the system picker; cancelling it leaves Verify empty.
            answerPicker(scenario, cancel = true)
            assertNull(vm(scenario).verifyDoc.value)
            scenario.onActivity {
                deliver(it, Intent(app, MainActivity::class.java).setAction(AppShortcuts.ACTION)
                    .putExtra(AppShortcuts.FEATURE, AppShortcuts.Destination.PrepareSigning.id))
            }
            compose.waitForIdle()
            answerPicker(scenario, Uri.fromFile(localFile("shortcut.pdf", "%PDF-1.7\n")))
            compose.waitUntil(30_000) { vm(scenario).signItems.value.any { it.doc.name == "shortcut.pdf" } }
        }
    }

    @Test fun androidDocumentAccessReadsCopiesAndDeletes() = runBlocking {
        val access = AndroidDocumentAccess(app)
        val source = Uri.fromFile(localFile("source.pdf", "%PDF-1.7 body"))
        val described = access.describe(source)
        assertEquals("source.pdf", described.name)
        assertEquals(13L, described.size)
        assertArrayEquals("%PDF".toByteArray(), access.readPrefix(source, 4))
        assertArrayEquals("%PDF-1.7 body".toByteArray(), access.readBytes(source, 1024))
        assertArrayEquals("%PDF-1.7 body".toByteArray(), access.readBytes(source))
        try { access.readBytes(source, 4); throw AssertionError("size limit") } catch (_: IllegalArgumentException) {}
        val copy = requireNotNull(access.copyToCache(source))
        assertTrue(File(copy.path!!).readText().startsWith("%PDF"))
        val target = Uri.fromFile(File(app.filesDir, "target.pdf"))
        assertTrue(access.copy(source, target))
        assertTrue(access.writeBytes(target, "replaced".toByteArray()))
        assertEquals("replaced", File(target.path!!).readText())
        access.keepAccess(source)
        assertTrue(access.delete(target))
        assertFalse(access.delete(Uri.parse("https://example.invalid/x")))
        assertNull(access.copyToCache(Uri.parse("content://missing/x")))
        assertFalse(access.copy(Uri.parse("content://missing/x"), target))
        Unit
    }

    @Test fun widgetShowsRecentDocumentsOnlyWhenAllowed() {
        val manager = AppWidgetManager.getInstance(app)
        val ids = shadowOf(manager).createWidgets(DocumentsWidget::class.java, R.layout.documents_widget, 1)
        DocumentsWidget.refresh(app)
        app.getSharedPreferences("settings", Context.MODE_PRIVATE).edit().putBoolean(DocumentsWidget.SHOW_RECENTS, true)
            .putString("widget_language", "en").commit()
        app.container.activity.document("signed-semnat.pdf", Uri.fromFile(localFile("signed-semnat.pdf", "%PDF")), ok = true,
            subtitle = "Signed", signedOutput = true)
        DocumentsWidget().onUpdate(app, manager, ids)
        assertNotNull(shadowOf(manager).getViewFor(ids.single()))
        assertTrue(manager.getAppWidgetIds(ComponentName(app, DocumentsWidget::class.java)).isNotEmpty())
    }

    @Test fun bridgeServiceRefusesDemoAndStops() {
        assertTrue(app.changeDemoMode(true))
        val controller = Robolectric.buildService(BridgeService::class.java, Intent(app, BridgeService::class.java)).create()
        controller.startCommand(0, 1)
        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        controller.destroy()
        assertFalse(BridgeService.running.value)
    }

    @Test fun bridgeServicePostsTheTrayNotification() {
        val controller = Robolectric.buildService(BridgeService::class.java, Intent(app, BridgeService::class.java)).create()
        controller.startCommand(0, 1)
        val notifications = shadowOf(app.getSystemService(NotificationManager::class.java)).allNotifications
        assertTrue(notifications.any { shadowOf(it).contentTitle == string(R.string.bridge_notification_title) })
        // Starting the HTTPS listener needs the bundled identity and free loopback ports: either outcome is reported.
        compose.waitUntil(30_000) { BridgeService.running.value || BridgeService.startupFailed.value || shadowOf(controller.get()).isStoppedBySelf }
        app.container.beginBusy()
        app.container.endBusy()
        controller.startCommand(0, 2)
        controller.destroy()
        assertFalse(BridgeService.running.value)
        val stop = Robolectric.buildService(BridgeService::class.java, Intent(app, BridgeService::class.java).setAction(BridgeService.ACTION_STOP)).create()
        stop.startCommand(0, 3)
        assertTrue(shadowOf(stop.get()).isStoppedBySelf)
        BridgeService.start(app)
        BridgeService.stop(app)
    }
}
