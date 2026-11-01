package md.moldsign.app.application

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class BookmarkUrlTest {
    @Test fun webAddressesRetainPathsAndFragments() {
        assertEquals("https://msign.gov.md/#/", BookmarkUrl.normalize(" msign.gov.md/#/ "))
        assertEquals("http://localhost:8080/document?x=1", BookmarkUrl.normalize("http://localhost:8080/document?x=1"))
    }

    @Test fun unsafeAndMalformedInputsAreRejected() {
        listOf("", "javascript:alert(1)", "file:///tmp/a.pdf", "https://user:password@example.com", "https://",
            "https://bad host.md/", "https://example.com:70000/", "https://example.com:0/", "https://example.com/with a space")
            .forEach { assertNull(it, BookmarkUrl.normalize(it)) }
    }

    @Test fun unknownSavedIconsUseGlobe() {
        assertEquals(BookmarkIcon.Globe, BookmarkIcon.fromKey("unknown"))
        assertEquals(BookmarkIcon.Person, BookmarkIcon.fromKey("person"))
    }
}
