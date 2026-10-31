package md.moldsign.app.infrastructure.demo

import md.moldsign.core.*
import org.junit.Assert.*
import org.junit.Test

class DemoServicesTest {
    @Test fun demoReaderCannotOpenPhysicalTransport() {
        val reader = DemoReaderGateway()
        reader.start()
        assertEquals(2, reader.readers.value.size)
        assertTrue(runCatching { reader.transportProvider.open(null) }.exceptionOrNull() is CardError.NoReader)
        reader.stop()
    }

    @Test fun mockSigningIgnoresRealInputAndNeverRequestsPin() {
        val service = DemoSigningService()
        val privateInput = "private document content"
        val result = service.signPdf(Document("private.pdf", privateInput.toByteArray()),
            Consent { fail("Demo must not request or consume a real PIN"); ConsentResult.Cancelled },
            null, "preview-1", null)
        assertTrue(result.output.toString(Charsets.UTF_8).contains("DEMO ONLY - NOT SIGNED"))
        assertFalse(result.output.toString(Charsets.UTF_8).contains(privateInput))
        assertNull(result.certificate.der)
        assertEquals("DEMO", result.format)
        assertEquals(SigningStep.Done, service.progress.value)
        assertTrue(runCatching {
            service.signDigestInfo(byteArrayOf(1), "private.pdf", Consent { error("No PIN") }, null, null, null)
        }.exceptionOrNull() is CardError.NoReader)
    }
}
