/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.popups;

import java.awt.Color;
import java.awt.Frame;
import java.awt.event.ActionEvent;
import java.net.URI;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.JButton;
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
import md.cts.moldsign.msccm.rest.clients.DecryptClient;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileSymmetricInputModel;
import md.ghesar.Resource;

public class DecryptWithPasswordDialog
extends JDialog {
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    private JButton btnDecrypt;
    private JPasswordField jpfPassword;
    private JTextField jtfInputFile;
    private JTextField jtfSaveFileTo;

    public DecryptWithPasswordDialog(Frame parent, boolean modal) {
        super(parent, modal);
        this.initComponents();
        this.getRootPane().setDefaultButton(this.btnDecrypt);
    }

    private void initComponents() {
        JPanel jPanel1 = new JPanel();
        JLabel jLabel1 = new JLabel();
        this.jtfInputFile = new JTextField();
        JButton btnBrowse = new JButton();
        JLabel jLabel3 = new JLabel();
        this.jtfSaveFileTo = new JTextField();
        JButton btnBrowseSave = new JButton();
        JLabel jLabel4 = new JLabel();
        this.jpfPassword = new JPasswordField();
        JButton btnCancel = new JButton();
        this.btnDecrypt = new JButton();
        JSeparator jSeparator1 = new JSeparator();
        this.setDefaultCloseOperation(2);
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("decrypt document with password"));
        this.setIconImage(Resource.getImage("/applogo.png"));
        jPanel1.setBorder(BorderFactory.createTitledBorder(null, bundle.getString("Decrypt document with password"), 0, 0, null, new Color(0, 0, 0)));
        jLabel1.setText(bundle.getString("select file to encrypt"));
        btnBrowse.setText(bundle.getString("btn.browse"));
        btnBrowse.addActionListener(this::btnBrowseActionPerformed);
        jLabel3.setText(bundle.getString("save file to"));
        btnBrowseSave.setText(bundle.getString("btn.browse"));
        btnBrowseSave.addActionListener(this::btnBrowseSaveActionPerformed);
        jLabel4.setText(bundle.getString("enter password"));
        btnCancel.setText(bundle.getString("btn.cancel"));
        btnCancel.addActionListener(this::btnCancelActionPerformed);
        this.btnDecrypt.setText(bundle.getString("btn.decrypt"));
        this.btnDecrypt.addActionListener(this::btnDecryptActionPerformed);
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jSeparator1).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(this.btnDecrypt).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(btnCancel)).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jLabel3).addComponent(jLabel1).addComponent(jLabel4)).addGap(26, 26, 26).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.TRAILING, false).addComponent(this.jpfPassword, -1, 367, Short.MAX_VALUE).addComponent(this.jtfInputFile).addComponent(this.jtfSaveFileTo)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, 9, Short.MAX_VALUE).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(btnBrowse, GroupLayout.Alignment.TRAILING).addComponent(btnBrowseSave, GroupLayout.Alignment.TRAILING)))).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel1).addComponent(this.jtfInputFile, -2, -1, -2).addComponent(btnBrowse)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnBrowseSave).addComponent(this.jtfSaveFileTo, -2, -1, -2).addComponent(jLabel3)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jLabel4).addComponent(this.jpfPassword, -2, -1, -2)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, 34, Short.MAX_VALUE).addComponent(jSeparator1, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnCancel).addComponent(this.btnDecrypt))));
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -2, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        this.pack();
    }

    private void btnBrowseActionPerformed(ActionEvent evt) {
        JFileChooser jfc = new JFileChooser();
        jfc.setAcceptAllFileFilterUsed(false);
        int result = jfc.showOpenDialog(this);
        if (result == 0) {
            String fileName = jfc.getSelectedFile().toString();
            this.jtfInputFile.setText(fileName);
            this.autoFillDestination(fileName);
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

    private void btnDecryptActionPerformed(ActionEvent evt) {
        if ("".equals(this.jtfInputFile.getText())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.please_select_file_to_decrypt"), this.rbundle.getString("sign.err_msg.please_select_file_to_decrypt"), 0);
            this.jtfInputFile.requestFocus();
            return;
        }
        if ("".equals(this.jtfSaveFileTo.getText())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.save_decrypted_file_to"), this.rbundle.getString("sign.err_msg.save_decrypted_file_to"), 0);
            this.jtfSaveFileTo.requestFocus();
            return;
        }
        if (this.jtfInputFile.getText().equals(this.jtfSaveFileTo.getText())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("decrypt.err_msg.destination_file_error"), this.rbundle.getString("decrypt.err_msg.destination_file_error"), 0);
            this.jtfSaveFileTo.setText("");
            this.jtfSaveFileTo.requestFocus();
            return;
        }
        if ("".equals(this.jpfPassword.getPassword())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.password_empty"), this.rbundle.getString("sign.err_msg.password_empty"), 0);
            this.jtfSaveFileTo.requestFocus();
            return;
        }
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, DecryptWithPasswordDialog.this.rbundle.getString("decryptSym.settingParams"));
                EncryptDecryptFileSymmetricInputModel decSym = new EncryptDecryptFileSymmetricInputModel();
                decSym.setFilePath(DecryptWithPasswordDialog.this.jtfInputFile.getText());
                decSym.setPassword(new String(DecryptWithPasswordDialog.this.jpfPassword.getPassword()));
                decSym.setSaveFileTo(DecryptWithPasswordDialog.this.jtfSaveFileTo.getText());
                this.firePropertyChange("currentOperation", null, DecryptWithPasswordDialog.this.rbundle.getString("decryptSym.decryptionOfTheFile"));
                DecryptClient dc = new DecryptClient();
                URI uri2 = dc.decryptSymetricPost(decSym);
                this.firePropertyChange("currentOperation", null, DecryptWithPasswordDialog.this.rbundle.getString("decryptSym.retreivingResults"));
                if (uri2 != null) {
                    EncryptDecryptFileResponseModel getResponse;
                    this.firePropertyChange("currentOperation", null, DecryptWithPasswordDialog.this.rbundle.getString("decrypt.progress.decryption_ok"));
                    try {
                        getResponse = dc.decryptAsymetricSymetricGet(uri2);
                    }
                    catch (ServerException ex) {
                        return new ProgressBarModel(DecryptWithPasswordDialog.this.rbundle.getString("decrypt.err_msg.decrypt_failed") + "\n" + ex.getMessage(), 0);
                    }
                    if (getResponse != null) {
                        this.setProgress(100);
                        DecryptWithPasswordDialog.this.cleanInputFields();
                        return new ProgressBarModel(DecryptWithPasswordDialog.this.rbundle.getString("decryption.ok"), 1);
                    }
                    return new ProgressBarModel(DecryptWithPasswordDialog.this.rbundle.getString("decrypt.err_msg.decrypt_failed"), 0);
                }
                return new ProgressBarModel(DecryptWithPasswordDialog.this.rbundle.getString("decrypt.err_msg.decrypt_failed"), 0);
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
    }

    private void autoFillDestination(String originalFileName) {
        if (originalFileName != null && !originalFileName.trim().isEmpty() && this.jtfSaveFileTo.getText().trim().isEmpty()) {
            int fileExtensionStart;
            String newFileName = originalFileName.endsWith(".mspe") ? ((fileExtensionStart = originalFileName.lastIndexOf(".")) < 0 ? originalFileName : originalFileName.substring(0, fileExtensionStart)) : originalFileName.concat(".decrypted");
            this.jtfSaveFileTo.setText(newFileName);
        }
    }

    public void setSelectedFile(String fileName) {
        this.jtfInputFile.setText(fileName);
        this.autoFillDestination(this.jtfInputFile.getText());
    }
}

