/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.DerInputException
 */
package md.cts.moldsign.msccm.popups;

import iaik.asn1.DerInputException;
import java.awt.Color;
import java.awt.Frame;
import java.awt.event.ActionEvent;
import java.io.IOException;
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
import javax.swing.JSeparator;
import javax.swing.JTextField;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.msccm.models.CustomCertificatePopupTableModel;
import md.cts.moldsign.msccm.models.ProgressBarModel;
import md.cts.moldsign.msccm.observers.SelectCertificateObserver;
import md.cts.moldsign.msccm.popups.CertificateTableSelectorDialog;
import md.cts.moldsign.msccm.popups.ProgressBarDialog;
import md.cts.moldsign.msccm.rest.clients.CertificatesClient;
import md.cts.moldsign.msccm.rest.clients.DecryptClient;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.DecryptFileAsymmetricInputModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.ghesar.Resource;

public class DecryptWithCertificateDialog
extends JDialog
implements SelectCertificateObserver {
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    final DecryptWithCertificateDialog self;
    final DecryptFileAsymmetricInputModel decAsym;
    private CertificateModel selectedCertificate;
    private JButton btnDecrypt;
    private JTextField jtfCertificate;
    private JTextField jtfInputFile;
    private JTextField jtfSaveFileTo;

    public DecryptWithCertificateDialog(Frame parent, boolean modal) {
        this(parent, modal, new DecryptFileAsymmetricInputModel());
    }

    public DecryptWithCertificateDialog(Frame parent, boolean modal, DecryptFileAsymmetricInputModel dasim) {
        super(parent, modal);
        this.initComponents();
        this.getRootPane().setDefaultButton(this.btnDecrypt);
        this.self = this;
        this.decAsym = dasim;
    }

    private void initComponents() {
        JPanel jPanel1 = new JPanel();
        JLabel jLabel1 = new JLabel();
        JLabel jLabel2 = new JLabel();
        this.jtfInputFile = new JTextField();
        JButton btnBrowse = new JButton();
        JLabel jLabel3 = new JLabel();
        this.jtfSaveFileTo = new JTextField();
        JButton btnBrowseSave = new JButton();
        JButton btnCancel = new JButton();
        this.btnDecrypt = new JButton();
        JSeparator jSeparator1 = new JSeparator();
        this.jtfCertificate = new JTextField();
        JButton btnSelectCertificate = new JButton();
        this.setDefaultCloseOperation(2);
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("decrypt document with certificate"));
        this.setIconImage(Resource.getImage("/applogo.png"));
        jPanel1.setBorder(BorderFactory.createTitledBorder(null, bundle.getString("decrypt document with certificate"), 0, 0, null, new Color(0, 0, 0)));
        jLabel1.setText(bundle.getString("select file to encrypt"));
        jLabel2.setText(bundle.getString("choose certificate"));
        btnBrowse.setText(bundle.getString("btn.browse"));
        btnBrowse.addActionListener(this::btnBrowseActionPerformed);
        jLabel3.setText(bundle.getString("save file to"));
        btnBrowseSave.setText(bundle.getString("btn.browse"));
        btnBrowseSave.addActionListener(this::btnBrowseSaveActionPerformed);
        btnCancel.setText(bundle.getString("btn.cancel"));
        btnCancel.addActionListener(this::btnCancelActionPerformed);
        this.btnDecrypt.setText(bundle.getString("btn.decrypt"));
        this.btnDecrypt.addActionListener(this::btnDecryptActionPerformed);
        this.jtfCertificate.setEditable(false);
        btnSelectCertificate.setText(bundle.getString("btn.choose"));
        btnSelectCertificate.addActionListener(this::btnSelectCertificateActionPerformed);
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jSeparator1).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jLabel1).addComponent(jLabel2).addComponent(jLabel3)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jtfCertificate, -1, 375, Short.MAX_VALUE).addComponent(this.jtfSaveFileTo).addComponent(this.jtfInputFile)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(btnBrowse, -2, 70, -2).addComponent(btnSelectCertificate, -2, 70, -2).addComponent(btnBrowseSave, GroupLayout.Alignment.TRAILING, -2, 70, -2))).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addGap(0, 406, Short.MAX_VALUE).addComponent(this.btnDecrypt).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnCancel))).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap(-1, Short.MAX_VALUE).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel1).addComponent(this.jtfInputFile, -2, -1, -2).addComponent(btnBrowse)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel2).addComponent(this.jtfCertificate, -2, -1, -2).addComponent(btnSelectCertificate)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel3).addComponent(this.jtfSaveFileTo, -2, -1, -2).addComponent(btnBrowseSave)).addGap(18, 18, Short.MAX_VALUE).addComponent(jSeparator1, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnCancel).addComponent(this.btnDecrypt)).addContainerGap(-1, Short.MAX_VALUE)));
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -2, -1, -2).addContainerGap(-1, Short.MAX_VALUE)));
        this.pack();
    }

    private void btnBrowseActionPerformed(ActionEvent evt) {
        JFileChooser jfc = new JFileChooser();
        jfc.setAcceptAllFileFilterUsed(false);
        int result = jfc.showOpenDialog(this);
        if (result == 0) {
            String originalFile = jfc.getSelectedFile().toString();
            this.jtfInputFile.setText(originalFile);
            this.autoFillDestination(originalFile);
            this.cleanSelectedCertificate();
            this.checkForSuitableCertificate(jfc.getSelectedFile().getAbsolutePath());
        }
    }

    private void checkForSuitableCertificate(String selectedFilePath) {
        try {
            CertificatesClient cc = new CertificatesClient();
            CertificateModel cm = cc.findEncryptedFileCertificate(selectedFilePath);
            this.onCertificateSelected(cm);
        }
        catch (DerInputException die) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("decrypt.err_message.the_selected_file_is_not_encrypted_with_a_certificate"), this.rbundle.getString("decrypt.err_message.the_selected_file_is_not_encrypted_with_a_certificate"), 1);
            this.cleanInputFields();
        }
        catch (IOException ioe) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("encryptdecrypt.err_message.problem_reading_the_file"), this.rbundle.getString("encryptdecrypt.err_message.problem_reading_the_file"), 0);
            this.cleanInputFields();
        }
        catch (ServerException se) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("decrypt.no_suitable_certificate_found"), this.rbundle.getString("decrypt.no_suitable_certificate_found"), 1);
            this.cleanInputFields();
        }
    }

    private void cleanSelectedCertificate() {
        this.selectedCertificate = null;
        this.jtfCertificate.setText("");
    }

    private void btnBrowseSaveActionPerformed(ActionEvent evt) {
        JFileChooser jfc = new JFileChooser();
        int result = jfc.showSaveDialog(this);
        if (result == 0) {
            String fileName = jfc.getSelectedFile().toString();
            this.autoFillDestination(fileName);
        }
    }

    private void btnCancelActionPerformed(ActionEvent evt) {
        this.dispose();
    }

    private void btnSelectCertificateActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, DecryptWithCertificateDialog.this.rbundle.getString("sign.progress.reading_certificates"));
                CertificateTableSelectorDialog csd = new CertificateTableSelectorDialog(null, true);
                csd.registerObserver(DecryptWithCertificateDialog.this.self);
                csd.setLocationRelativeTo(DecryptWithCertificateDialog.this.self);
                csd.setVisible(true);
                return null;
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
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
        if ("".equals(this.jtfCertificate.getText())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.certificateFieldEmpty"), this.rbundle.getString("sign.err_msg.certificateFieldEmpty"), 0);
            this.jtfSaveFileTo.requestFocus();
            return;
        }
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, DecryptWithCertificateDialog.this.rbundle.getString("decryptSym.settingParams"));
                DecryptWithCertificateDialog.this.decAsym.setFilePath(DecryptWithCertificateDialog.this.jtfInputFile.getText());
                DecryptWithCertificateDialog.this.decAsym.setSaveFileTo(DecryptWithCertificateDialog.this.jtfSaveFileTo.getText());
                DecryptWithCertificateDialog.this.decAsym.setCertificate(DecryptWithCertificateDialog.this.selectedCertificate);
                this.firePropertyChange("currentOperation", null, DecryptWithCertificateDialog.this.rbundle.getString("decryptSym.decryptionOfTheFile"));
                DecryptClient dc = new DecryptClient();
                URI uri2 = dc.decryptAsymetricPost(DecryptWithCertificateDialog.this.decAsym);
                this.firePropertyChange("currentOperation", null, DecryptWithCertificateDialog.this.rbundle.getString("decryptSym.retreivingResults"));
                if (uri2 != null) {
                    EncryptDecryptFileResponseModel getResponse;
                    this.firePropertyChange("currentOperation", null, DecryptWithCertificateDialog.this.rbundle.getString("decrypt.progress.decryption_ok"));
                    try {
                        getResponse = dc.decryptAsymetricSymetricGet(uri2);
                    }
                    catch (ServerException ex) {
                        return new ProgressBarModel(DecryptWithCertificateDialog.this.rbundle.getString("decrypt.err_msg.decrypt_failed") + "\n" + ex.getMessage(), 0);
                    }
                    if (getResponse != null) {
                        this.setProgress(100);
                        DecryptWithCertificateDialog.this.cleanInputFields();
                        return new ProgressBarModel(DecryptWithCertificateDialog.this.rbundle.getString("decryption.ok"), 1);
                    }
                    return new ProgressBarModel(DecryptWithCertificateDialog.this.rbundle.getString("decrypt.err_msg.decrypt_failed"), 0);
                }
                return new ProgressBarModel(DecryptWithCertificateDialog.this.rbundle.getString("decrypt.err_msg.decrypt_failed"), 0);
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    public void cleanInputFields() {
        this.jtfSaveFileTo.setText("");
        this.jtfInputFile.setText("");
        this.jtfCertificate.setText("");
    }

    @Override
    public void onCertificateSelected(CertificateModel cm) {
        this.selectedCertificate = cm;
        this.jtfCertificate.setText(CustomCertificatePopupTableModel.getNameFromDN(this.selectedCertificate.getCertificate().getSubjectDN()));
    }

    private void autoFillDestination(String originalFileName) {
        if (originalFileName != null && !originalFileName.trim().isEmpty()) {
            int fileExtensionStart;
            String newFileName = originalFileName.endsWith(".msce") ? ((fileExtensionStart = originalFileName.lastIndexOf(".")) < 0 ? originalFileName : originalFileName.substring(0, fileExtensionStart)) : originalFileName.concat(".decrypted");
            this.jtfSaveFileTo.setText(newFileName);
        }
    }

    public void setSelectedFile(String fileName) {
        this.jtfInputFile.setText(fileName);
        this.autoFillDestination(this.jtfInputFile.getText());
    }
}

