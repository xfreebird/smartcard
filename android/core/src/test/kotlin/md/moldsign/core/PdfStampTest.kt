package md.moldsign.core

import java.time.ZonedDateTime
import org.junit.Assert.*
import org.junit.Test

class PdfStampTest {
    private val catalog = "<< /Type /Catalog /Pages 1 0 R >>"
    private val pdf = """
        1 0 obj << /Type /Pages /Kids [3 0 R 2 0 R] /Count 2 /MediaBox [0 0 600 800] /CropBox [20 30 520 730] /Rotate 90 >> endobj
        2 0 obj << /Type /Page /Parent 1 0 R /Rotate 0 /Annots [] >> endobj
        3 0 obj << /Type /Page /Parent 1 0 R /Annots 7 0 R /Private (keep /Annots [999 0 R]) >> endobj
        7 0 obj [8 0 R] endobj
    """.trimIndent()
    private fun create(placement: PdfStampPlacement) = StampPdf.appearance(pdf,catalog,12,10,13,"Signature1",placement,"Ștefan Țurcanu Иванов",ZonedDateTime.parse("2026-11-06T10:00:00Z"))

    @Test fun allPagesUsesOneWidgetAndLinksBackToIt() {
        val a=create(PdfStampPlacement(allPages=true,x=.1,y=.2,width=.4,height=.1))
        val update=a.chunks.joinToString("")
        assertEquals(1,Regex("/Subtype /Widget").findAll(update).count())
        assertEquals(1,Regex("/Subtype /Stamp").findAll(update).count())
        assertTrue(update.contains("/Dest [3 0 R /FitR 120.00000 100.00000 170.00000 380.00000]"))
        assertTrue(update.contains("/Annots [8 0 R "))
        assertTrue(update.contains("/Private (keep /Annots [999 0 R])"))
        assertTrue(update.contains("/Matrix [0 1 -1 0 96 0]"))
        assertTrue(a.field.contains("/V 10 0 R"))
    }
    @Test fun singlePageDoesNotUpdateOtherPages() {
        val a=create(PdfStampPlacement(page=1))
        assertTrue(a.chunks.any { it.startsWith("2 0 obj") })
        assertFalse(a.chunks.any { it.startsWith("3 0 obj") })
    }
    @Test fun rejectsOffPageAndNonFinitePlacement() {
        listOf(PdfStampPlacement(page=3),PdfStampPlacement(x=Double.NaN),PdfStampPlacement(x=.9)).forEach {
            assertThrows(CardError.Format::class.java) { create(it) }
        }
    }
}
