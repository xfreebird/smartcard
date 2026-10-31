package md.moldsign.core

import java.util.Date
import org.junit.Assert.*
import org.junit.Test

class BatchConsentTest {
    private val cert = CertificateSummary("DEMO", "CN=DEMO", "CN=DEMO CA", "DEMO CA", Date(0), Date(Long.MAX_VALUE), "01", "demo-cert")
    private fun request(name: String = "one.pdf") = ConsentRequest(null, listOf(name), "PAdES-T", cert)

    @Test fun oneAuthorizationListsTheFrozenBatchAndSuppliesIndependentPinCopies() {
        val documents = mutableListOf("one.pdf", "two.pdf")
        val prompts = mutableListOf<ConsentRequest>()
        val batch = BatchConsent(Consent { prompts += it; ConsentResult.Pin(charArrayOf('0','0','0','0')) }, documents)
        documents += "unapproved.pdf"
        val first = batch.obtain(request()) as ConsentResult.Pin
        first.pin.fill('x') // The signing service wipes each per-file copy after VERIFY.
        val second = batch.obtain(request("two.pdf")) as ConsentResult.Pin
        assertArrayEquals(charArrayOf('0','0','0','0'), second.pin)
        assertEquals(1, prompts.size)
        assertEquals(listOf("one.pdf", "two.pdf"), prompts.single().documentNames)
        batch.close()
        assertSame(ConsentResult.Cancelled, batch.obtain(request()))
        second.pin.fill('\u0000')
    }

    @Test fun changedCertificateStopsTheSessionWithoutAnotherPrompt() {
        var prompts = 0
        val batch = BatchConsent(Consent { prompts++; ConsentResult.Pin(charArrayOf('0')) })
        batch.obtain(request())
        assertSame(ConsentResult.Cancelled, batch.obtain(request().copy(certificate = cert.copy(sha1Hex = "different"))))
        assertSame(ConsentResult.Cancelled, batch.obtain(request()))
        assertEquals(1, prompts)
    }

    @Test fun anotherRequesterCannotUseThePin() {
        val batch = BatchConsent(Consent { ConsentResult.Pin(charArrayOf('0')) })
        batch.obtain(request())
        assertSame(ConsentResult.Cancelled, batch.obtain(request().copy(requester = "https://other.example")))
    }

    @Test fun anUnapprovedDocumentCannotUseThePin() {
        val batch = BatchConsent(Consent { ConsentResult.Pin(charArrayOf('0')) }, listOf("one.pdf"))
        batch.obtain(request())
        assertSame(ConsentResult.Cancelled, batch.obtain(request("other.pdf")))
    }

    @Test fun cancellationIsTerminalAndDoesNotPromptAgain() {
        var prompts = 0
        val batch = BatchConsent(Consent { prompts++; ConsentResult.Cancelled })
        assertSame(ConsentResult.Cancelled, batch.obtain(request()))
        assertSame(ConsentResult.Cancelled, batch.obtain(request()))
        assertEquals(1, prompts)
    }
    @Test fun anUnapprovedFormatCannotUseThePin() {
        val batch = BatchConsent(Consent { ConsentResult.Pin(charArrayOf('0')) }, allowedFormats = setOf("PAdES-T"))
        batch.obtain(request())
        assertSame(ConsentResult.Cancelled, batch.obtain(request().copy(format = "PKCS#1")))
    }

    @Test fun providerFailureEndsTheSessionWithoutReprompting() {
        var prompts = 0
        val batch = BatchConsent(Consent { prompts++; throw IllegalStateException("fictional provider failure") })
        try { batch.obtain(request()); fail("expected provider failure") } catch (_: IllegalStateException) { }
        assertSame(ConsentResult.Cancelled, batch.obtain(request()))
        assertEquals(1, prompts)
    }

}
