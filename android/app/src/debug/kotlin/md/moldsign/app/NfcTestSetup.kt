package md.moldsign.app

import android.content.Intent
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import android.net.Uri
import md.moldsign.app.application.AppContainer
import md.moldsign.app.presentation.MainViewModel
import java.io.File

/** Prepares one visibly synthetic PDF in the separate test install. Never starts signing or supplies a PIN. */
internal object NfcTestSetup {
    fun apply(container: AppContainer, intent: Intent?, vm: MainViewModel) {
        if (!BuildConfig.APPLICATION_ID.endsWith(".nfctest") || container.isDemo ||
            intent?.getBooleanExtra("nfc_test_prepare", false) != true) return
        val file = File(container.app.cacheDir, "NFC-signing-test.pdf")
        val document = PdfDocument()
        try {
            val page = document.startPage(PdfDocument.PageInfo.Builder(595, 842, 1).create())
            val paint = Paint().apply { color = android.graphics.Color.BLACK; textSize = 22f }
            page.canvas.drawColor(android.graphics.Color.WHITE)
            page.canvas.drawText("NFC signing test", 50f, 80f, paint)
            paint.textSize = 13f
            page.canvas.drawText("Synthetic document for testing eSemnBun on Android.", 50f, 120f, paint)
            page.canvas.drawText("It contains no personal information or commitments.", 50f, 145f, paint)
            document.finishPage(page)
            file.outputStream().use(document::writeTo)
        } finally { document.close() }
        vm.addForSigning(listOf(Uri.fromFile(file)))
        vm.selectSigningMethod(MainViewModel.SigningMethod.NFC)
    }
}
