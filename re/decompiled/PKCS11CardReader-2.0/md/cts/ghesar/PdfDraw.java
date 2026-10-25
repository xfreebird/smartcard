/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.gov.stisc.AppProp
 *  org.apache.pdfbox.pdmodel.PDDocument
 *  org.apache.pdfbox.pdmodel.PDPage
 *  org.apache.pdfbox.pdmodel.common.PDRectangle
 *  org.apache.pdfbox.rendering.PDFRenderer
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.ghesar;

import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Point;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.geom.AffineTransform;
import java.io.IOException;
import java.io.InputStream;
import javax.swing.JComponent;
import md.gov.stisc.AppProp;
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
    private final int rw = 220;
    private final int rh = 60;
    private PDDocument document;
    private PDFRenderer renderer;
    private int pageCount = 0;
    private int pageNum = 0;
    private int rx = 40;
    private int ry = 30;
    private Event event = null;

    public PdfDraw(InputStream input) {
        Integer box = AppProp.getInt((String)"sign.position.s");
        if (box != null && box == 1) {
            box = AppProp.getInt((String)"sign.position.p");
            if (box != null) {
                this.pageNum = box;
            }
            if ((box = AppProp.getInt((String)"sign.position.x")) != null) {
                this.rx = box;
            }
            if ((box = AppProp.getInt((String)"sign.position.y")) != null) {
                this.ry = box;
            }
        }
        float cbw = 0.0f;
        float cbh = 0.0f;
        try {
            this.document = PDDocument.load((InputStream)input);
            this.pageCount = this.document.getNumberOfPages();
            this.renderer = new PDFRenderer(this.document);
            if (this.pageNum >= this.pageCount) {
                this.pageNum = this.pageCount - 1;
            }
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
            if (this.event != null) {
                this.event.run();
            }
        });
        RedMouseAdapter ma = new RedMouseAdapter();
        this.addMouseListener(ma);
        this.addMouseMotionListener(ma);
    }

    public void setEventListener(Event event) {
        this.event = event;
    }

    public void close() {
        try {
            this.document.close();
        }
        catch (IOException ex) {
            logger.error("close", (Throwable)ex);
        }
    }

    public void movePage(int page) {
        this.pageNum += page;
        if (this.pageNum < 0) {
            this.pageNum = 0;
        } else if (this.pageNum >= this.pageCount) {
            this.pageNum = this.pageCount - 1;
        }
        this.repaint();
    }

    public void gotoPage(int page) {
        this.pageNum = page;
        if (this.pageNum < 0) {
            this.pageNum = 0;
        } else if (this.pageNum >= this.pageCount) {
            this.pageNum = this.pageCount - 1;
        }
        this.repaint();
    }

    public int getPageCount() {
        return this.pageCount;
    }

    public int getCurrentPage() {
        return this.pageNum + 1;
    }

    public Point getSigPoint() {
        AppProp.setInt((String)"sign.position.p", (Integer)this.pageNum);
        AppProp.setInt((String)"sign.position.x", (Integer)this.rx);
        AppProp.setInt((String)"sign.position.y", (Integer)this.ry);
        float scale = this.h / (float)this.getHeight();
        return new Point((int)((float)this.rx * scale), (int)(this.h - (float)this.ry * scale));
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2 = (Graphics2D)g;
        AffineTransform origTransform = g2.getTransform();
        float scale = (float)this.getHeight() / this.h;
        if (this.renderer != null) {
            try {
                this.renderer.renderPageToGraphics(this.pageNum, g2, scale);
            }
            catch (Exception ex) {
                logger.error("paintComponent", (Throwable)ex);
            }
        }
        g2.setClip(null);
        g2.setTransform(origTransform);
        g2.setPaintMode();
        g2.setColor(Color.RED);
        g2.drawRect(this.rx, this.ry, 220, 60);
    }

    public static interface Event {
        public void run();
    }

    private final class RedMouseAdapter
    extends MouseAdapter {
        private RedMouseAdapter() {
        }

        private void calculate(int x, int y) {
            PdfDraw.this.rx = x - 110;
            PdfDraw.this.ry = y - 30;
            if (PdfDraw.this.rx < 0) {
                PdfDraw.this.rx = 0;
            }
            if (PdfDraw.this.ry < 0) {
                PdfDraw.this.ry = 0;
            }
            int mw = PdfDraw.this.getWidth() - 220 - 1;
            int mh = PdfDraw.this.getHeight() - 60 - 1;
            if (PdfDraw.this.rx > mw) {
                PdfDraw.this.rx = mw;
            }
            if (PdfDraw.this.ry > mh) {
                PdfDraw.this.ry = mh;
            }
            PdfDraw.this.repaint();
        }

        @Override
        public void mousePressed(MouseEvent ev) {
            this.calculate(ev.getX(), ev.getY());
        }

        @Override
        public void mouseReleased(MouseEvent ev) {
            this.calculate(ev.getX(), ev.getY());
        }

        @Override
        public void mouseDragged(MouseEvent ev) {
            this.calculate(ev.getX(), ev.getY());
        }
    }
}

