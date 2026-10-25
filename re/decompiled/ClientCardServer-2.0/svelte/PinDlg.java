/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package svelte;

import java.awt.Color;
import java.awt.Container;
import java.awt.Dialog;
import java.awt.Dimension;
import java.awt.Image;
import java.awt.Window;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPasswordField;
import javax.swing.KeyStroke;
import javax.swing.border.EmptyBorder;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import svelte.PinCallback;

public final class PinDlg {
    private static final Logger logger = LoggerFactory.getLogger(PinDlg.class);
    private JDialog dlg;

    private PinDlg() {
    }

    public static void display(JDialog owner, PinCallback callback) {
        PinDlg view = new PinDlg();
        view.init(owner, callback);
    }

    private void init(JDialog owner, PinCallback callback) {
        logger.info("display Pin dialog");
        this.dlg = new JDialog((Window)owner, "Enter token pin", Dialog.ModalityType.APPLICATION_MODAL);
        this.dlg.setDefaultCloseOperation(2);
        this.dlg.getRootPane().registerKeyboardAction(e -> this.dlg.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.dlg.setTitle(bundle.getString("enterpin.title"));
        this.dlg.setIconImage(Resource.getImage((String)"/applogo.png"));
        JLabel labelImage1 = new JLabel();
        labelImage1.setOpaque(true);
        labelImage1.setBackground(Color.WHITE);
        labelImage1.setHorizontalAlignment(0);
        labelImage1.setBorder(new EmptyBorder(0, 4, 0, 4));
        ImageIcon imageIcon = new ImageIcon(Resource.getImage((String)"/stisc_logo.png"));
        float k = 0.6f;
        int nw = (int)((float)imageIcon.getIconWidth() * k);
        int nh = (int)((float)imageIcon.getIconHeight() * k);
        Image image = imageIcon.getImage();
        image = image.getScaledInstance(nw, nh, 4);
        imageIcon = new ImageIcon(image);
        labelImage1.setIcon(imageIcon);
        JButton btnOk = new JButton();
        btnOk.setText(bundle.getString("btn.ok"));
        JButton btnCancel = new JButton();
        btnCancel.setText(bundle.getString("btn.cancel"));
        JLabel label2 = new JLabel();
        label2.setText(bundle.getString("lbl.enterPin"));
        JPasswordField password1 = new JPasswordField();
        btnOk.addActionListener(e -> {
            this.dlg.dispose();
            callback.run(true, password1.getPassword());
        });
        btnCancel.addActionListener(e -> this.dlg.dispose());
        Container pane = this.dlg.getContentPane();
        GroupLayout layout = new GroupLayout(pane);
        pane.setLayout(layout);
        layout.setAutoCreateGaps(true);
        layout.setHorizontalGroup(layout.createParallelGroup().addComponent(labelImage1, 0, -1, Short.MAX_VALUE).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(label2).addComponent(password1).addContainerGap()).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addComponent(btnOk).addComponent(btnCancel).addContainerGap()));
        layout.setVerticalGroup(layout.createSequentialGroup().addComponent(labelImage1).addGap(4, 16, Short.MAX_VALUE).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(label2).addComponent(password1)).addGap(4, 16, Short.MAX_VALUE).addGroup(layout.createParallelGroup().addComponent(btnOk).addComponent(btnCancel)).addContainerGap());
        this.dlg.setMinimumSize(new Dimension(310, 96));
        this.dlg.pack();
        this.dlg.getRootPane().setDefaultButton(btnOk);
        this.dlg.setLocationRelativeTo(owner);
        this.dlg.setAlwaysOnTop(true);
        this.dlg.requestFocus();
        this.dlg.setVisible(true);
    }
}

