/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.itextpdf.kernel.pdf.PdfAConformance
 *  com.itextpdf.kernel.pdf.PdfConformance
 *  com.itextpdf.kernel.pdf.PdfDocument
 *  com.itextpdf.kernel.pdf.PdfReader
 *  com.itextpdf.kernel.pdf.PdfWriter
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo.iso;

import com.itextpdf.kernel.pdf.PdfAConformance;
import com.itextpdf.kernel.pdf.PdfConformance;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.kernel.pdf.PdfWriter;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class Kayak {
    private static final Logger logger = LoggerFactory.getLogger(Kayak.class);

    /*
     * Enabled aggressive block sorting
     * Enabled unnecessary exception pruning
     * Enabled aggressive exception aggregation
     */
    public static boolean stripCompliance(String inputPath, String outputPath) {
        try (PdfReader reader = new PdfReader(inputPath);
             PdfDocument inputDoc = new PdfDocument(reader);){
            PdfConformance conform = inputDoc.getConformance();
            PdfAConformance a = conform.getAConformance();
            if (a == null) return false;
            try (PdfWriter writer = new PdfWriter(outputPath);
                 PdfDocument outputDoc = new PdfDocument(writer);){
                inputDoc.copyPagesTo(1, inputDoc.getNumberOfPages(), outputDoc);
            }
            boolean bl = true;
            return bl;
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        return false;
    }
}

