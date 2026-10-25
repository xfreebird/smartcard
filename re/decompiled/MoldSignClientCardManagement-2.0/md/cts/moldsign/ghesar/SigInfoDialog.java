/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.ghesar;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Container;
import java.awt.Dialog;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Image;
import java.awt.Window;
import java.io.InputStream;
import javax.swing.BorderFactory;
import javax.swing.BoxLayout;
import javax.swing.ButtonGroup;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JToggleButton;
import javax.swing.KeyStroke;
import javax.swing.border.EmptyBorder;
import md.cts.moldsign.ghesar.PdfFile;
import md.cts.moldsign.ghesar.PdfView;
import md.cts.moldsign.ghesar.SigInfo;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SigInfoDialog {
    private static final Logger logger = LoggerFactory.getLogger(SigInfoDialog.class);
    private JDialog dlg;
    private JLabel textArea;
    private String activeSignatureName;

    private SigInfoDialog() {
    }

    public static void show(Window parent, PdfFile pdfFile) {
        SigInfoDialog sigView = new SigInfoDialog();
        sigView.init(parent, pdfFile);
    }

    private static void pad(StringBuilder sb, String name, String value) {
        sb.append(name);
        sb.append(":  ");
        sb.append(value);
        sb.append("<br>");
    }

    private void init(Window parent, PdfFile pdfFile) {
        Image img;
        this.dlg = new JDialog(parent, "Signatures for    " + pdfFile.getFileName(), Dialog.ModalityType.APPLICATION_MODAL);
        this.dlg.getRootPane().registerKeyboardAction(e -> this.dlg.setVisible(false), KeyStroke.getKeyStroke(27, 0), 2);
        Container pane = this.dlg.getContentPane();
        JPanel leftPanel = new JPanel();
        BoxLayout boxLayout = new BoxLayout(leftPanel, 1);
        leftPanel.setLayout(boxLayout);
        leftPanel.setBorder(new EmptyBorder(5, 5, 5, 0));
        leftPanel.setMinimumSize(new Dimension(300, 220));
        leftPanel.setPreferredSize(new Dimension(300, 220));
        pane.add((Component)leftPanel, "Before");
        JPanel centerPanel = new JPanel(new BorderLayout());
        pane.add((Component)centerPanel, "Center");
        centerPanel.setBorder(new EmptyBorder(0, 5, 5, 5));
        JPanel topPanel = new JPanel(new FlowLayout(0, 5, 5));
        centerPanel.add((Component)topPanel, "First");
        JPanel bottomPanel = new JPanel(new FlowLayout(2, 5, 5));
        centerPanel.add((Component)bottomPanel, "Last");
        JButton button = new JButton("Close");
        button.addActionListener(e -> this.dlg.setVisible(false));
        bottomPanel.add(button);
        JButton buttonViewPDF = new JButton("View PDF");
        buttonViewPDF.addActionListener(ev -> {
            InputStream input;
            if (this.activeSignatureName != null && (input = pdfFile.extractRevision(this.activeSignatureName)) != null) {
                new PdfView(parent, input, pdfFile.getFileName());
            }
        });
        topPanel.add(buttonViewPDF);
        this.textArea = new JLabel();
        this.textArea.setVerticalAlignment(1);
        this.textArea.setBorder(new EmptyBorder(2, 2, 2, 2));
        JScrollPane scrollPane = new JScrollPane(this.textArea);
        scrollPane.setBorder(BorderFactory.createLineBorder(Color.LIGHT_GRAY));
        centerPanel.add((Component)scrollPane, "Center");
        boolean verdict = true;
        ButtonGroup buttonGroup = new ButtonGroup();
        for (int i = 0; i < pdfFile.signList.size(); ++i) {
            Image img2;
            SigInfo sig = pdfFile.signList.get(i);
            String lab = "<html><body>" + sig.personName + "<br>" + sig.formattedDate + "</body></html>";
            JToggleButton b = new JToggleButton(lab);
            b.setHorizontalAlignment(2);
            if (sig.isValid && sig.isTimestampValid) {
                img2 = Resource.getImage("/check.png");
            } else {
                img2 = Resource.getImage("/delete.png");
                verdict = false;
            }
            if (img2 != null) {
                b.setIcon(new ImageIcon(img2));
            }
            b.addActionListener(e -> {
                this.activeSignatureName = sig.signatureName;
                this.showText(sig);
                buttonViewPDF.setEnabled(true);
            });
            buttonGroup.add(b);
            leftPanel.add(b);
            if (i != 0) continue;
            b.setSelected(true);
            this.activeSignatureName = sig.signatureName;
            this.showText(sig);
        }
        if (verdict && !(verdict = pdfFile.getLastSigWhole())) {
            verdict = pdfFile.checkAux();
        }
        Object lab = "<html><body><b>";
        if (verdict) {
            lab = (String)lab + "<span color=\"green\">has not been altered</span>";
            img = Resource.getImage("/check.png");
        } else {
            lab = (String)lab + "<span color=\"red\">has been altered</span>";
            img = Resource.getImage("/delete.png");
        }
        lab = (String)lab + "</b></body></html>";
        JButton b = new JButton((String)lab);
        b.setHorizontalAlignment(2);
        if (img != null) {
            b.setIcon(new ImageIcon(img));
        }
        String txt = verdict ? "<html><span color=\"green\">The document has not been modified since the signature was applied" : "<html><span color=\"red\">The document has been modified since the signature was applied";
        b.addActionListener(e -> {
            this.activeSignatureName = null;
            this.textArea.setText(txt);
            buttonViewPDF.setEnabled(false);
        });
        leftPanel.add(b);
        this.dlg.setSize(1200, 540);
        this.dlg.setLocationRelativeTo(parent);
        this.dlg.setVisible(true);
    }

    private void showText(SigInfo sig) {
        StringBuilder sb = new StringBuilder();
        sb.append("<html>");
        if (sig.isValid) {
            sb.append("<b color=\"green\">Signature is VALID</b><br>");
            sb.append(" - The document has not been modified since the signature was applied<br>");
        } else {
            sb.append("<b color=\"red\">Signature is NOT VALID</b><br>");
        }
        if (sig.isTimestampValid) {
            sb.append(" - Timestamp is VALID<br>");
        } else {
            sb.append("<span color=\"red\"> - Timestamp is NOT VALID</span><br>");
        }
        sb.append("<br>");
        SigInfoDialog.pad(sb, "Signer", sig.personName);
        SigInfoDialog.pad(sb, "SERIALNUMBER", sig.serialNumber);
        SigInfoDialog.pad(sb, "Organization", sig.organization);
        sb.append("<br>");
        SigInfoDialog.pad(sb, "Time", sig.formattedDate);
        SigInfoDialog.pad(sb, "Reason", sig.pdfPk.getReason());
        SigInfoDialog.pad(sb, "Location", sig.pdfPk.getLocation());
        sb.append("<br>");
        this.textArea.setText(sb.toString());
    }
}

