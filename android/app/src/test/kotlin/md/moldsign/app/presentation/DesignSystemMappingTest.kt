package md.moldsign.app.presentation

import md.moldsign.app.ui.theme.StatusTone
import md.moldsign.core.StatusLight
import org.junit.Assert.assertEquals
import org.junit.Test

class DesignSystemMappingTest {
    @Test fun everyCoreStatusHasAnExplicitPresentationTone() {
        assertEquals(StatusTone.Success, StatusLight.Ready.toTone())
        assertEquals(StatusTone.Warning, StatusLight.Reader.toTone())
        assertEquals(StatusTone.Busy, StatusLight.Busy.toTone())
        assertEquals(StatusTone.Danger, StatusLight.Error.toTone())
        assertEquals(StatusTone.Idle, StatusLight.Idle.toTone())
    }

    @Test fun missingOrMalformedIdentityKeepsNeutralCardArt() {
        listOf(null, "", "f", "zz").forEach { assertEquals(0f, cardHueShift(it), 0f) }
        assertEquals(-20f, cardHueShift("00a1"), 0f)
        assertEquals(20f, cardHueShift("FFa1"), 0f)
    }
}
