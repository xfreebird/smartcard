package md.moldsign.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AppShortcutsTest {
    @Test fun onlyExplicitKnownFeaturesAreRouted() {
        AppShortcuts.Destination.entries.forEach {
            assertEquals(it, AppShortcuts.resolve(AppShortcuts.ACTION, true, it.id))
        }
        listOf(null, "", "sign", "file:///Download/private.pdf", "verify_pdf/extra").forEach {
            assertNull(AppShortcuts.resolve(AppShortcuts.ACTION, true, it))
        }
    }
    @Test fun missingFeatureOpensDocumentsButOtherActionsAreIgnored() {
        assertEquals(AppShortcuts.Destination.Documents, AppShortcuts.resolve(AppShortcuts.ACTION, false, null))
        listOf(null, "android.intent.action.SEND", "android.intent.action.VIEW").forEach {
            assertNull(AppShortcuts.resolve(it, true, "verify_pdf"))
        }
    }
}
