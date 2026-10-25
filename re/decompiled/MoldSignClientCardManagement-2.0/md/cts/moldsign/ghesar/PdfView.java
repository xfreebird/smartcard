/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.ghesar;

import java.awt.Component;
import java.awt.Container;
import java.awt.Dialog;
import java.awt.GraphicsConfiguration;
import java.awt.Insets;
import java.awt.Rectangle;
import java.awt.Window;
import java.io.InputStream;
import javax.swing.JDialog;
import javax.swing.KeyStroke;
import md.cts.moldsign.ghesar.PdfDraw;
import md.ghesar.Resource;

public final class PdfView {
    private final JDialog dlg;
    private PdfDraw draw;

    public PdfView(Window parent, InputStream input, String fileName) {
        this.dlg = new JDialog(parent, fileName, Dialog.ModalityType.APPLICATION_MODAL);
        this.dlg.setIconImage(Resource.getImage("/applogo.png"));
        this.init(input);
        GraphicsConfiguration gc = this.dlg.getGraphicsConfiguration();
        Rectangle bounds = gc.getBounds();
        Insets insets = this.dlg.getToolkit().getScreenInsets(gc);
        this.dlg.pack();
        Insets dlgInset = this.dlg.getInsets();
        int x = bounds.x + insets.left;
        int y = bounds.y + insets.top;
        int w = bounds.width - (insets.left + insets.right + dlgInset.left + dlgInset.right);
        int h = bounds.height - (insets.top + insets.bottom + dlgInset.top + dlgInset.bottom + 15);
        float scale = (float)h / this.draw.h;
        float drawWidth = this.draw.w * scale;
        x += (int)(((float)w - drawWidth) / 2.0f);
        w = (int)drawWidth;
        this.dlg.setBounds(x, y, w, h);
        this.dlg.setVisible(true);
    }

    private void init(InputStream input) {
        this.dlg.getRootPane().registerKeyboardAction(e -> {
            this.draw.close();
            this.dlg.setVisible(false);
        }, KeyStroke.getKeyStroke(27, 0), 2);
        Container pane = this.dlg.getContentPane();
        this.draw = new PdfDraw(input);
        pane.add((Component)this.draw, "Center");
    }
}

