/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.pin_providers;

import java.awt.Color;
import java.awt.Image;
import java.awt.event.ActionEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.LayoutStyle;
import javax.swing.border.EmptyBorder;
import md.cts.pkcs11.providers.pin_providers.NoMoreAttemptsException;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class EnterPinDialog
extends JFrame {
    private static final Logger logger = LoggerFactory.getLogger(EnterPinDialog.class);
    private boolean okPressed;
    private JButton btnEnterPinOk;
    private JPasswordField jPasswordField1;
    private JLabel lblRequester;
    private JLabel origin;
    private JPanel pnlWarning;

    public EnterPinDialog(String requester) {
        logger.info("new EnterPinDialog");
        this.setAlwaysOnTop(true);
        this.initComponents();
        if (requester != null) {
            this.origin.setText(requester);
        } else {
            this.origin.setVisible(false);
            this.lblRequester.setVisible(false);
        }
        this.setLocationRelativeTo(null);
        this.requestFocus();
        this.getRootPane().setDefaultButton(this.btnEnterPinOk);
    }

    private void initComponents() {
        this.setDefaultCloseOperation(2);
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("enterpin.title"));
        this.setIconImage(Resource.getImage((String)"/applogo.png"));
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
        this.jPasswordField1 = new JPasswordField();
        this.pnlWarning = new JPanel();
        JLabel jLabel3 = new JLabel();
        this.lblRequester = new JLabel();
        this.origin = new JLabel();
        this.addWindowListener(new WindowAdapter(){

            @Override
            public void windowClosing(WindowEvent evt) {
                EnterPinDialog.this.onWindowClosing(evt);
            }
        });
        this.btnEnterPinOk = new JButton();
        this.btnEnterPinOk.setText(bundle.getString("btn.ok"));
        this.btnEnterPinOk.addActionListener(this::btnEnterPinOkActionPerformed);
        JButton btnCancel = new JButton();
        btnCancel.setText(bundle.getString("btn.cancel"));
        btnCancel.addActionListener(this::btnCancelActionPerformed);
        JLabel jLabel1 = new JLabel();
        jLabel1.setText(bundle.getString("lbl.enterPin"));
        this.pnlWarning.setBorder(BorderFactory.createEtchedBorder());
        jLabel3.setText(bundle.getString("lbl.enterpin.last_attempt_warning"));
        GroupLayout pnlWarningLayout = new GroupLayout(this.pnlWarning);
        this.pnlWarning.setLayout(pnlWarningLayout);
        pnlWarningLayout.setHorizontalGroup(pnlWarningLayout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(pnlWarningLayout.createSequentialGroup().addContainerGap().addComponent(jLabel3, -1, -1, Short.MAX_VALUE).addContainerGap()));
        pnlWarningLayout.setVerticalGroup(pnlWarningLayout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(pnlWarningLayout.createSequentialGroup().addContainerGap().addComponent(jLabel3).addContainerGap(-1, Short.MAX_VALUE)));
        this.lblRequester.setText(ResourceBundle.getBundle("translations").getString("lbl.enterpin.requester"));
        this.origin.setText(this.origin.getText());
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(labelImage1, 0, -1, Short.MAX_VALUE).addGroup(layout.createSequentialGroup().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addComponent(this.pnlWarning, -1, -1, Short.MAX_VALUE).addContainerGap()).addGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addGap(0, 178, Short.MAX_VALUE)).addGroup(layout.createSequentialGroup().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jLabel1).addComponent(this.lblRequester)).addGap(16, 16, 16).addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jPasswordField1).addComponent(this.origin, -1, -1, Short.MAX_VALUE)))).addContainerGap()).addGroup(layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(this.btnEnterPinOk).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnCancel).addGap(14, 14, 14)))));
        layout.setVerticalGroup(layout.createSequentialGroup().addComponent(labelImage1).addGap(4, 16, Short.MAX_VALUE).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel1).addComponent(this.jPasswordField1, -2, -1, -2)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED, -1, Short.MAX_VALUE).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.lblRequester).addComponent(this.origin)).addGap(4, 16, Short.MAX_VALUE).addComponent(this.pnlWarning, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.btnEnterPinOk).addComponent(btnCancel)).addContainerGap());
        this.lblRequester.getAccessibleContext().setAccessibleName("<lbl.enterpin.requester>");
        this.pack();
    }

    private void btnEnterPinOkActionPerformed(ActionEvent evt) {
        this.okPressed = true;
        this.buttonClicked();
    }

    private void btnCancelActionPerformed(ActionEvent evt) {
        this.okPressed = false;
        this.buttonClicked();
    }

    private void onWindowClosing(WindowEvent evt) {
        this.okPressed = false;
        this.buttonClicked();
    }

    private synchronized void buttonClicked() {
        this.notify();
    }

    private synchronized char[] getValue() throws NoMoreAttemptsException {
        this.setVisible(true);
        try {
            this.wait();
        }
        catch (InterruptedException ex) {
            throw new NoMoreAttemptsException();
        }
        this.setVisible(false);
        if (this.okPressed) {
            return this.jPasswordField1.getPassword();
        }
        throw new NoMoreAttemptsException();
    }

    public char[] getNextPin() throws NoMoreAttemptsException {
        return this.getNextPin(false);
    }

    public char[] getNextPin(boolean lastAttempt) throws NoMoreAttemptsException {
        this.jPasswordField1.setText("");
        this.pnlWarning.setVisible(lastAttempt);
        this.pack();
        return this.getValue();
    }
}

