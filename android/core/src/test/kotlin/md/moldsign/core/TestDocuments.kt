package md.moldsign.core

import java.nio.charset.StandardCharsets.ISO_8859_1

/** Fictional documents for the signer and validator tests. */
internal object TestDocuments {
    /** A minimal valid one-page PDF with a classic xref table. */
    fun samplePdf(): ByteArray {
        val sb = StringBuilder("%PDF-1.4\n")
        val offsets = ArrayList<Int>()
        fun obj(n: Int, body: String) {
            offsets += sb.length
            sb.append("$n 0 obj\n$body\nendobj\n")
        }
        obj(1, "<</Type/Catalog/Pages 2 0 R>>")
        obj(2, "<</Type/Pages/Kids[3 0 R]/Count 1>>")
        obj(3, "<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>")
        val xref = sb.length
        sb.append("xref\n0 4\n0000000000 65535 f \n")
        offsets.forEach { sb.append("%010d 00000 n \n".format(it)) }
        sb.append("trailer\n<</Size 4/Root 1 0 R/ID[<0123456789ABCDEF0123456789ABCDEF><0123456789ABCDEF0123456789ABCDEF>]>>\n")
        sb.append("startxref\n$xref\n%%EOF\n")
        return sb.toString().toByteArray(ISO_8859_1)
    }
}
