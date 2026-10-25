/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 *  md.gov.stisc.AppProp
 */
package md.cts.ghesar;

import java.awt.BorderLayout;
import java.awt.Component;
import java.awt.Container;
import java.awt.Dialog;
import java.awt.GraphicsConfiguration;
import java.awt.Insets;
import java.awt.Point;
import java.awt.Rectangle;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.KeyStroke;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import md.cts.ghesar.PdfDraw;
import md.ghesar.Resource;
import md.gov.stisc.AppProp;

public final class PdfView {
    private final JDialog dlg;
    private PdfDraw draw;
    private boolean appearance = true;
    private boolean success = false;

    public PdfView(String fileName) throws IOException {
        Path pat = Paths.get(fileName, new String[0]);
        InputStream input = Files.newInputStream(pat, new OpenOption[0]);
        this.dlg = new JDialog(null, pat.getFileName().toString(), Dialog.ModalityType.APPLICATION_MODAL);
        this.dlg.setAlwaysOnTop(true);
        this.dlg.setIconImage(Resource.getImage((String)"/applogo.png"));
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

    public boolean getSuccess() {
        return this.success;
    }

    public boolean getAppearance() {
        return this.appearance;
    }

    public Point getSigPoint() {
        return this.draw.getSigPoint();
    }

    public int getFinalPage() {
        return this.draw.getCurrentPage();
    }

    private void init(InputStream input) {
        this.dlg.getRootPane().registerKeyboardAction(e -> {
            this.draw.close();
            this.dlg.setVisible(false);
        }, KeyStroke.getKeyStroke(27, 0), 2);
        Container pane = this.dlg.getContentPane();
        this.draw = new PdfDraw(input);
        pane.add((Component)this.draw, "Center");
        this.initCom(pane);
    }

    private void initCom(Container pane) {
        JPanel panel1 = new JPanel(new BorderLayout());
        pane.add((Component)panel1, "Last");
        JPanel panel2 = new JPanel();
        panel1.add((Component)panel2, "Before");
        JPanel panel3 = new JPanel();
        panel1.add((Component)panel3, "Center");
        JButton buttonAccept = new JButton("Accept");
        panel3.add(buttonAccept);
        JButton buttonNoSignatureImage = new JButton("No Appearance");
        panel3.add(buttonNoSignatureImage);
        final JLabel totalPage = new JLabel();
        totalPage.setHorizontalAlignment(2);
        totalPage.setText(this.draw.getCurrentPage() + " / " + this.draw.getPageCount());
        panel2.add(totalPage);
        JButton backButton = new JButton();
        backButton.setText("<");
        panel2.add(backButton);
        JButton nextButton = new JButton();
        nextButton.setText(">");
        panel2.add(nextButton);
        final JTextField selectPage = new JTextField("1");
        panel2.add(selectPage);
        JCheckBox checkBox = new JCheckBox("Save signature position");
        panel2.add(checkBox);
        Integer box = AppProp.getInt((String)"sign.position.s");
        if (box != null && box == 1) {
            checkBox.setSelected(true);
        }
        this.draw.setEventListener(() -> {
            totalPage.setText(this.draw.getCurrentPage() + " / " + this.draw.getPageCount());
            selectPage.setText("" + this.draw.getCurrentPage());
        });
        selectPage.getDocument().addDocumentListener(new DocumentListener(){

            @Override
            public void insertUpdate(DocumentEvent e) {
                this.changedUpdate(e);
            }

            @Override
            public void removeUpdate(DocumentEvent e) {
                this.changedUpdate(e);
            }

            @Override
            public void changedUpdate(DocumentEvent e) {
                int val = 1;
                try {
                    val = Integer.parseInt(selectPage.getText());
                }
                catch (Exception exception) {
                    // empty catch block
                }
                PdfView.this.draw.gotoPage(val - 1);
                totalPage.setText(PdfView.this.draw.getCurrentPage() + " / " + PdfView.this.draw.getPageCount());
            }
        });
        backButton.addActionListener(ev -> {
            this.draw.movePage(-1);
            totalPage.setText(this.draw.getCurrentPage() + " / " + this.draw.getPageCount());
            selectPage.setText("" + this.draw.getCurrentPage());
        });
        nextButton.addActionListener(ev -> {
            this.draw.movePage(1);
            totalPage.setText(this.draw.getCurrentPage() + " / " + this.draw.getPageCount());
            selectPage.setText("" + this.draw.getCurrentPage());
        });
        buttonAccept.addActionListener(ev -> {
            this.success = true;
            this.dlg.dispose();
        });
        buttonNoSignatureImage.addActionListener(ev -> {
            this.appearance = false;
            this.success = true;
            this.dlg.dispose();
        });
        checkBox.addItemListener(e -> {
            boolean saveState = e.getStateChange() == 1;
            AppProp.setInt((String)"sign.position.s", (Integer)(saveState ? 1 : 0));
        });
        this.dlg.getRootPane().setDefaultButton(buttonAccept);
    }
}

