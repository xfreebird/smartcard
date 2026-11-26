package md.moldsign.app.testing

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.pdf.PdfDocument
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import java.io.OutputStream

/**
 * Robolectric has no native PDF writer. Pages draw onto real bitmaps (native graphics), and the written file is a
 * small, well-formed PDF with one page object per finished page, so the app's own fixtures can be produced.
 */
@Implements(PdfDocument::class)
class ShadowPdfDocument {
    private var pages = 0
    private var closed = false

    @Implementation
    fun startPage(info: PdfDocument.PageInfo): PdfDocument.Page {
        check(!closed) { "document is closed!" }
        val constructor = PdfDocument.Page::class.java.getDeclaredConstructor(Canvas::class.java, PdfDocument.PageInfo::class.java)
        constructor.isAccessible = true
        return constructor.newInstance(Canvas(Bitmap.createBitmap(info.pageWidth, info.pageHeight, Bitmap.Config.ARGB_8888)), info)
    }

    @Implementation
    fun finishPage(@Suppress("UNUSED_PARAMETER") page: PdfDocument.Page) { pages++ }

    @Implementation
    fun writeTo(out: OutputStream) {
        val body = StringBuilder("%PDF-1.7\n1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n")
        body.append("2 0 obj << /Type /Pages /Count $pages >> endobj\n")
        repeat(pages) { body.append("${it + 3} 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] >> endobj\n") }
        body.append("trailer << /Root 1 0 R >>\n%%EOF\n")
        out.write(body.toString().toByteArray())
    }

    @Implementation
    fun close() { closed = true }
}
