/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.popups;

import java.awt.Color;
import java.awt.Frame;
import java.awt.event.ActionEvent;
import java.net.URI;
import java.util.Arrays;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.DefaultComboBoxModel;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JDialog;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JSeparator;
import javax.swing.JTextField;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.msccm.models.ProgressBarModel;
import md.cts.moldsign.msccm.popups.ProgressBarDialog;
import md.cts.moldsign.msccm.rest.clients.EncryptClient;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileSymmetricInputModel;
import md.ghesar.Resource;

public class EncryptWithPasswordDialog
extends JDialog {
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    private JButton btnEncrypt;
    private JComboBox<String> cmbAlgorithms;
    private JPasswordField jpfPassword;
    private JPasswordField jpfPasswordConfirm;
    private JTextField jtfInputFile;
    private JTextField jtfSaveFileTo;

    public EncryptWithPasswordDialog(Frame parent, boolean modal) {
        super(parent, modal);
        this.initComponents();
        this.getRootPane().setDefaultButton(this.btnEncrypt);
    }

    private void initComponents() {
        JPanel jPanel1 = new JPanel();
        JLabel lblFile = new JLabel();
        JLabel lblAlgorithm = new JLabel();
        this.jtfInputFile = new JTextField();
        JButton btnBrowse = new JButton();
        this.cmbAlgorithms = new JComboBox();
        JLabel lblDestination = new JLabel();
        this.jtfSaveFileTo = new JTextField();
        JButton btnBrowseSave = new JButton();
        JLabel lblPassword = new JLabel();
        this.jpfPassword = new JPasswordField();
        JButton btnCancel = new JButton();
        this.btnEncrypt = new JButton();
        JSeparator jSeparator1 = new JSeparator();
        JLabel lblPasswordConfirm = new JLabel();
        this.jpfPasswordConfirm = new JPasswordField();
        this.setDefaultCloseOperation(2);
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("encrypt document with password"));
        this.setIconImage(Resource.getImage("/applogo.png"));
        jPanel1.setBorder(BorderFactory.createTitledBorder(null, bundle.getString("encrypt document with password"), 0, 0, null, new Color(0, 0, 0)));
        lblFile.setLabelFor(this.jtfInputFile);
        lblFile.setText(bundle.getString("select file to encrypt"));
        lblAlgorithm.setLabelFor(this.cmbAlgorithms);
        lblAlgorithm.setText(bundle.getString("choose algorithm"));
        btnBrowse.setText(bundle.getString("btn.browse"));
        btnBrowse.addActionListener(this::btnBrowseActionPerformed);
        this.cmbAlgorithms.setModel(new DefaultComboBoxModel<String>(new String[]{"3_KeyTripleDES_CBC", "2_KeyTripleDES_CBC", "DES_CBC", "RC2_CBC", "RC4", "128bit_AES", "192bit_AES", "256bit_AES"}));
        lblDestination.setLabelFor(this.jtfSaveFileTo);
        lblDestination.setText(bundle.getString("save file to"));
        btnBrowseSave.setText(bundle.getString("btn.browse"));
        btnBrowseSave.addActionListener(this::btnBrowseSaveActionPerformed);
        lblPassword.setLabelFor(this.jpfPassword);
        lblPassword.setText(bundle.getString("encryptSum.enter_password"));
        btnCancel.setText(bundle.getString("btn.cancel"));
        btnCancel.addActionListener(this::btnCancelActionPerformed);
        this.btnEncrypt.setText(bundle.getString("btn.encrypt"));
        this.btnEncrypt.addActionListener(this::btnEncryptActionPerformed);
        lblPasswordConfirm.setLabelFor(this.jpfPasswordConfirm);
        lblPasswordConfirm.setText(bundle.getString("encryptSum.confirm_password"));
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jSeparator1).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING, false).addComponent(lblPasswordConfirm, -1, -1, Short.MAX_VALUE).addComponent(lblPassword, -1, -1, Short.MAX_VALUE).addComponent(lblDestination, -1, -1, Short.MAX_VALUE).addComponent(lblAlgorithm, -1, -1, Short.MAX_VALUE).addComponent(lblFile, -1, -1, Short.MAX_VALUE)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jtfInputFile).addComponent(this.cmbAlgorithms, 0, 373, Short.MAX_VALUE).addComponent(this.jtfSaveFileTo).addComponent(this.jpfPassword).addComponent(this.jpfPasswordConfirm)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(btnBrowse).addComponent(btnBrowseSave))).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(this.btnEncrypt).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnCancel))).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblFile).addComponent(this.jtfInputFile, -2, -1, -2).addComponent(btnBrowse)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblAlgorithm).addComponent(this.cmbAlgorithms, -2, -1, -2)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblDestination).addComponent(this.jtfSaveFileTo, -2, -1, -2).addComponent(btnBrowseSave)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblPassword).addComponent(this.jpfPassword, -2, -1, -2)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblPasswordConfirm).addComponent(this.jpfPasswordConfirm, -2, -1, -2)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, 23, Short.MAX_VALUE).addComponent(jSeparator1, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnCancel).addComponent(this.btnEncrypt))));
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        this.pack();
    }

    private void btnBrowseActionPerformed(ActionEvent evt) {
        JFileChooser jfc = new JFileChooser();
        jfc.setAcceptAllFileFilterUsed(false);
        int result = jfc.showOpenDialog(this);
        if (result == 0) {
            this.jtfInputFile.setText(jfc.getSelectedFile().toString());
            this.autoFillDestination(this.jtfInputFile.getText());
        }
    }

    private void btnBrowseSaveActionPerformed(ActionEvent evt) {
        JFileChooser jfc = new JFileChooser();
        int result = jfc.showSaveDialog(this);
        if (result == 0) {
            String fileName = jfc.getSelectedFile().toString();
            this.jtfSaveFileTo.setText(fileName);
        }
    }

    private void btnCancelActionPerformed(ActionEvent evt) {
        this.dispose();
    }

    private void btnEncryptActionPerformed(ActionEvent evt) {
        if ("".equals(this.jtfInputFile.getText())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.please_select_file_to_encrypt"), this.rbundle.getString("sign.err_msg.please_select_file_to_encrypt"), 0);
            this.jtfInputFile.requestFocus();
            return;
        }
        if ("".equals(this.jtfSaveFileTo.getText())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.save_encrypted_file_to"), this.rbundle.getString("sign.err_msg.save_encrypted_file_to"), 0);
            this.jtfSaveFileTo.requestFocus();
            return;
        }
        if (new String(this.jpfPassword.getPassword()).isEmpty()) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.password_empty"), this.rbundle.getString("sign.err_msg.password_empty"), 0);
            this.jpfPassword.requestFocus();
            return;
        }
        if (!Arrays.equals(this.jpfPassword.getPassword(), this.jpfPasswordConfirm.getPassword())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.passwords_dont_match"), this.rbundle.getString("sign.err_msg.passwords_dont_match"), 0);
            this.jpfPassword.requestFocus();
            return;
        }
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, EncryptWithPasswordDialog.this.rbundle.getString("encryptSym.settingParams"));
                EncryptDecryptFileSymmetricInputModel encSym = new EncryptDecryptFileSymmetricInputModel();
                encSym.setAlgorithm((String)EncryptWithPasswordDialog.this.cmbAlgorithms.getSelectedItem());
                encSym.setFilePath(EncryptWithPasswordDialog.this.jtfInputFile.getText());
                encSym.setPassword(new String(EncryptWithPasswordDialog.this.jpfPassword.getPassword()));
                encSym.setSaveFileTo(EncryptWithPasswordDialog.this.jtfSaveFileTo.getText());
                this.firePropertyChange("currentOperation", null, EncryptWithPasswordDialog.this.rbundle.getString("encryptSym.encryptionOfTheFile"));
                EncryptClient ec = new EncryptClient();
                URI uri2 = ec.encryptSymetricPost(encSym);
                this.firePropertyChange("currentOperation", null, EncryptWithPasswordDialog.this.rbundle.getString("encryptSym.retreivingResults"));
                if (uri2 != null) {
                    EncryptDecryptFileResponseModel getResponse;
                    this.firePropertyChange("currentOperation", null, EncryptWithPasswordDialog.this.rbundle.getString("encrypt.progress.encryption_ok"));
                    try {
                        getResponse = ec.encryptAsymetricSymetricGet(uri2);
                    }
                    catch (ServerException ex) {
                        return new ProgressBarModel(EncryptWithPasswordDialog.this.rbundle.getString("sign.err_msg.sign_failed") + "\n" + ex.getMessage(), 0);
                    }
                    if (getResponse != null) {
                        this.setProgress(100);
                        EncryptWithPasswordDialog.this.cleanInputFields();
                        return new ProgressBarModel(EncryptWithPasswordDialog.this.rbundle.getString("encryption.ok"), 1);
                    }
                    return new ProgressBarModel(EncryptWithPasswordDialog.this.rbundle.getString("encrypt.err_msg.encrypt_failed"), 0);
                }
                return new ProgressBarModel(EncryptWithPasswordDialog.this.rbundle.getString("encrypt.err_msg.encrypt_failed"), 0);
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    public void cleanInputFields() {
        this.jtfSaveFileTo.setText("");
        this.jtfInputFile.setText("");
        this.jpfPassword.setText("");
        this.jpfPasswordConfirm.setText("");
    }

    private void autoFillDestination(String originalFileName) {
        if (originalFileName != null && !originalFileName.trim().isEmpty()) {
            String destinationFileName = originalFileName.concat(".mspe");
            if (this.jtfSaveFileTo.getText().trim().isEmpty()) {
                this.jtfSaveFileTo.setText(destinationFileName);
            }
        }
    }

    public void setSelectedFile(String fileName) {
        this.jtfInputFile.setText(fileName);
        this.autoFillDestination(this.jtfInputFile.getText());
    }
}

