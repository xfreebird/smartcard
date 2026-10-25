/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.panels.tabs;

import java.awt.Color;
import java.awt.Font;
import java.awt.event.ActionEvent;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.ButtonGroup;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.JSeparator;
import javax.swing.LayoutStyle;
import md.cts.moldsign.msccm.TabPanel;
import md.cts.moldsign.msccm.popups.DecryptWithCertificateDialog;
import md.cts.moldsign.msccm.popups.DecryptWithPasswordDialog;
import md.cts.moldsign.msccm.popups.EncryptWithCertificateDialog;
import md.cts.moldsign.msccm.popups.EncryptWithPasswordDialog;

public class EncryptionDecryptionPanel
extends JPanel
implements TabPanel {
    final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    private JButton btnOk;
    private JPanel jPanel1;
    private JSeparator jSeparator1;
    private JRadioButton rbtDecPass;
    private JRadioButton rbtEncPass;

    public EncryptionDecryptionPanel() {
        this.initComponents();
        this.initRadioButtons();
    }

    private void initComponents() {
        this.jPanel1 = new JPanel();
        this.rbtEncPass = new JRadioButton();
        this.rbtDecPass = new JRadioButton();
        this.jSeparator1 = new JSeparator();
        this.btnOk = new JButton();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.jPanel1.setBorder(BorderFactory.createTitledBorder(null, bundle.getString("encryptdecrypt.title.border"), 0, 0, new Font("Dialog", 1, 12), new Color(0, 0, 0)));
        this.rbtEncPass.setText(bundle.getString("encryptwithpassword"));
        this.rbtEncPass.setName("encPass");
        this.rbtEncPass.addActionListener(this::rbtEncPassActionPerformed);
        this.rbtDecPass.setText(bundle.getString("decryptwithpassword"));
        this.rbtDecPass.setName("decPass");
        this.rbtDecPass.addActionListener(this::rbtDecPassActionPerformed);
        this.btnOk.setText(bundle.getString("encrypt.btn.encrypt"));
        this.btnOk.addActionListener(this::btnOkActionPerformed);
        GroupLayout jPanel1Layout = new GroupLayout(this.jPanel1);
        this.jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jSeparator1).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(this.btnOk)).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.rbtDecPass).addComponent(this.rbtEncPass)).addGap(0, 430, Short.MAX_VALUE))).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addComponent(this.rbtEncPass).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.rbtDecPass).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, 317, Short.MAX_VALUE).addComponent(this.jSeparator1, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.btnOk)));
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(this.jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(this.jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
    }

    private void btnOkActionPerformed(ActionEvent evt) {
        if (this.rbtEncPass.isSelected()) {
            EncryptWithPasswordDialog ewpd = new EncryptWithPasswordDialog(null, true);
            ewpd.setLocationRelativeTo(this);
            ewpd.setVisible(true);
        }
        if (this.rbtDecPass.isSelected()) {
            DecryptWithPasswordDialog dwpd = new DecryptWithPasswordDialog(null, true);
            dwpd.setLocationRelativeTo(this);
            dwpd.setVisible(true);
        }
    }

    private void rbtEncPassActionPerformed(ActionEvent evt) {
        this.btnOk.setText(this.rbundle.getString("encrypt.btn.encrypt"));
    }

    private void rbtDecPassActionPerformed(ActionEvent evt) {
        this.btnOk.setText(this.rbundle.getString("decrypt.btn.decrypt"));
    }

    private void initRadioButtons() {
        ButtonGroup bg = new ButtonGroup();
        bg.add(this.rbtDecPass);
        bg.add(this.rbtEncPass);
        this.rbtEncPass.setSelected(true);
    }

    @Override
    public void setSelectedFile(String action, String fileName) {
        if (action == null) {
            return;
        }
        if (action.equals("-encr_pass")) {
            EncryptWithPasswordDialog ewpd = new EncryptWithPasswordDialog(null, true);
            ewpd.setSelectedFile(fileName);
            ewpd.setLocationRelativeTo(this);
            ewpd.setVisible(true);
        }
        if (action.equals("-decr_pass")) {
            DecryptWithPasswordDialog dwpd = new DecryptWithPasswordDialog(null, true);
            dwpd.setSelectedFile(fileName);
            dwpd.setLocationRelativeTo(this);
            dwpd.setVisible(true);
        }
        if (action.equals("-encr_cert")) {
            EncryptWithCertificateDialog ewcd = new EncryptWithCertificateDialog(null, true);
            ewcd.setSelectedFile(fileName);
            ewcd.setLocationRelativeTo(this);
            ewcd.setVisible(true);
        }
        if (action.equals("-decr_cert")) {
            DecryptWithCertificateDialog dwcd = new DecryptWithCertificateDialog(null, true);
            dwcd.setSelectedFile(fileName);
            dwcd.setLocationRelativeTo(this);
            dwcd.setVisible(true);
        }
    }
}

