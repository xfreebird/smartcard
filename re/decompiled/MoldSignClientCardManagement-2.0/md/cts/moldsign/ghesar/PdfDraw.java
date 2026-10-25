/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.apache.pdfbox.pdmodel.PDDocument
 *  org.apache.pdfbox.pdmodel.PDPage
 *  org.apache.pdfbox.pdmodel.common.PDRectangle
 *  org.apache.pdfbox.rendering.PDFRenderer
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.ghesar;

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.io.IOException;
import java.io.InputStream;
import javax.swing.JComponent;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class PdfDraw
extends JComponent {
    private static final Logger logger = LoggerFactory.getLogger(PdfDraw.class);
    public final float w;
    public final float h;
    private PDDocument document;
    private PDFRenderer renderer;
    private int pageCount = 0;
    private int pageNum = 0;

    public PdfDraw(InputStream input) {
        float cbw = 0.0f;
        float cbh = 0.0f;
        try {
            this.document = PDDocument.load((InputStream)input);
            this.pageCount = this.document.getNumberOfPages();
            this.renderer = new PDFRenderer(this.document);
            PDPage page = this.document.getPage(this.pageNum);
            PDRectangle cropBox = page.getCropBox();
            cbw = cropBox.getWidth();
            cbh = cropBox.getHeight();
        }
        catch (Exception ex) {
            logger.error("PdfDraw", (Throwable)ex);
        }
        this.w = cbw;
        this.h = cbh;
        this.addMouseWheelListener(ev -> {
            int steps = ev.getWheelRotation();
            this.pageNum += steps;
            if (this.pageNum < 0) {
                this.pageNum = 0;
            } else if (this.pageNum >= this.pageCount) {
                this.pageNum = this.pageCount - 1;
            }
            this.repaint();
        });
    }

    public void close() {
        try {
            this.document.close();
        }
        catch (IOException ex) {
            logger.error("close", (Throwable)ex);
        }
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2 = (Graphics2D)g;
        float scale = (float)this.getHeight() / this.h;
        if (this.renderer != null) {
            try {
                this.renderer.renderPageToGraphics(this.pageNum, g2, scale);
            }
            catch (Exception ex) {
                logger.error("paintComponent", (Throwable)ex);
            }
        }
    }
}

