package md.moldsign.app.infrastructure.demo

import android.graphics.Color
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import java.io.ByteArrayOutputStream

/** A standalone fixture PDF. Never accepts a user document or any signing material. */
internal object DemoOutputRenderer {
    fun render(): ByteArray {
        val pdf = PdfDocument()
        try {
        val page = pdf.startPage(PdfDocument.PageInfo.Builder(612, 792, 1).create())
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.rgb(170, 30, 30); textSize = 22f }
        page.canvas.drawText("DEMO - NOT A VALID SIGNATURE", 50f, 100f, paint)
        paint.apply { color = Color.DKGRAY; textSize = 16f }
        page.canvas.drawText("Fictional sample document", 50f, 155f, paint)
        page.canvas.drawText("No real card, certificate or PIN was used.", 50f, 195f, paint)
        page.canvas.drawText("This file cannot be used as a signed document.", 50f, 225f, paint)
        paint.apply { color = Color.rgb(170, 30, 30); textSize = 18f }
        page.canvas.drawText("DEMO ONLY - UNSIGNED", 50f, 725f, paint)
        pdf.finishPage(page)
        return ByteArrayOutputStream().use { output -> pdf.writeTo(output); output.toByteArray() }
        } finally { pdf.close() }
    }
}
