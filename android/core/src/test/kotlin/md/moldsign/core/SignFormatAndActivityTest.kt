package md.moldsign.core

import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/**
 * The format chosen for a file reaches the right signer (a PDF can be signed as PAdES-T or as a detached XAdES over
 * its bytes), output names follow `<name>-semnat.<ext>`, and the activity list keeps only reachable documents.
 */
class SignFormatAndActivityTest {
    private val v = SpecFiles.cardCrypto
    private val pdf = Document("contract.pdf", "%PDF-1.7\n%fictional test document\n%%EOF\n".toByteArray())
    private val text = Document("cerere.txt", "cerere fictiva".toByteArray())

    private class Recorder : PadesSigner, XadesSigner {
        val calls = mutableListOf<String>()

        override fun sign(pdf: ByteArray, certificateDer: ByteArray, chainDer: List<ByteArray>, signer: RawSigner): ByteArray {
            calls += "PAdES"
            return "signed-pdf".toByteArray()
        }

        override fun sign(
            documents: List<Document>,
            level: XadesLevel,
            packaging: XadesPackaging,
            certificateDer: ByteArray,
            chainDer: List<ByteArray>,
            signer: RawSigner,
            digest: XadesDigest,
        ): ByteArray {
            calls += "XAdES-${level.name}/$packaging/${documents.joinToString { "${it.name}:${it.bytes.size}" }}"
            return "<xades/>".toByteArray()
        }
    }

    private fun service(recorder: Recorder) = CardSigningService(
        TransportProvider { SimulatedCard(v, TestCertificates.mdQSign) },
        MutableStateFlow(ReaderState.NoReader),
        pades = recorder,
        xades = recorder,
    )

    private val noConsent = Consent { fail("the fake signers never ask for the PIN"); ConsentResult.Cancelled }

    @Test
    fun formatOptionsAndDefaults() {
        assertEquals(listOf("PAdES-T", "XAdES-BES", "XAdES-T", "XAdES-C"), SignFormat.options(isPdf = true).map { it.label })
        assertEquals(listOf("XAdES-BES", "XAdES-T", "XAdES-C"), SignFormat.options(isPdf = false).map { it.label })
        assertEquals(SignFormat.PadesT, SignFormat.default(isPdf = true))
        assertEquals(SignFormat.XadesT, SignFormat.default(isPdf = false))
    }

    @Test
    fun outputNames() {
        assertEquals("contract-semnat.pdf", SignFormat.outputName("contract.pdf", SignFormat.PadesT))
        assertEquals("contract-semnat.xml", SignFormat.outputName("contract.pdf", SignFormat.XadesC))
        assertEquals("act.final-semnat.xml", SignFormat.outputName("act.final.docx", SignFormat.XadesT))
        assertEquals("README-semnat.xml", SignFormat.outputName("README", SignFormat.XadesBes))
    }

    @Test
    fun pdfFollowsTheChosenFormat() {
        val recorder = Recorder()
        val s = service(recorder)
        assertEquals("PAdES-T", s.sign(pdf, SignFormat.PadesT, noConsent).format)
        assertEquals("XAdES-T", s.sign(pdf, SignFormat.XadesT, noConsent).format)
        assertEquals("XAdES-C", s.sign(pdf, SignFormat.XadesC, noConsent).format)
        assertEquals(
            listOf("PAdES", "XAdES-T/Detached/contract.pdf:${pdf.bytes.size}", "XAdES-C/Detached/contract.pdf:${pdf.bytes.size}"),
            recorder.calls,
        )
    }

    @Test
    fun padesOnANonPdfIsRefusedBeforeTheCard() {
        val recorder = Recorder()
        try {
            service(recorder).sign(text, SignFormat.PadesT, noConsent)
            fail("expected CardError.Format")
        } catch (e: CardError.Format) {
            assertTrue(e.message!!.contains("cerere.txt"))
        }
        assertEquals(emptyList<String>(), recorder.calls)
        assertEquals("XAdES-BES", service(recorder).sign(text, SignFormat.XadesBes, noConsent).format)
    }

    @Test
    fun activityKeepsReachableDocumentsAndEveryBrowserEntry() {
        fun doc(id: String, uri: String?) = ActivityEntry(id, ActivityEntry.Kind.Document, "$id.pdf", "Semnat", true, 0, uri)
        val browser = ActivityEntry("b", ActivityEntry.Kind.Browser, "msign.gov.md", "Semnat · PAdES-T", true, 0)
        val list = listOf(doc("kept", "content://a"), doc("gone", "content://b"), browser, doc("nouri", null))
        assertEquals(listOf("kept", "b"), ActivityHistory.pruned(list, reachable = { it == "content://a" }).map { it.id })

        var many = emptyList<ActivityEntry>()
        repeat(ActivityHistory.MAX_ENTRIES + 5) { many = ActivityHistory.add(many, doc("e$it", "content://$it")) }
        assertEquals(ActivityHistory.MAX_ENTRIES, many.size)
        assertEquals("newest first", "e${ActivityHistory.MAX_ENTRIES + 4}", many.first().id)
    }
}
