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
import md.cts.moldsign.msccm.rest.clients.EncryptClient;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.moldsign.transferobjects.models.EncryptFileAsymmetricInputModel;
import md.ghesar.Resource;

public class EncryptWithCertificateDialog
extends JDialog
implements SelectCertificateObserver {
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    final EncryptWithCertificateDialog self;
    private CertificateModel selectedCertificate;
    private JButton btnEncrypt;
    private JTextField jtfCertificate;
    private JTextField jtfInputFile;
    private JTextField jtfSaveFileTo;

    public EncryptWithCertificateDialog(Frame parent, boolean modal) {
        super(parent, modal);
        this.initComponents();
        this.getRootPane().setDefaultButton(this.btnEncrypt);
        this.self = this;
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
        this.btnEncrypt = new JButton();
        JSeparator jSeparator1 = new JSeparator();
        this.jtfCertificate = new JTextField();
        JButton btnSelectCertificate = new JButton();
        this.setDefaultCloseOperation(2);
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("encrypt document with certificate"));
        this.setIconImage(Resource.getImage("/applogo.png"));
        jPanel1.setBorder(BorderFactory.createTitledBorder(null, bundle.getString("encrypt document with certificate"), 0, 0, null, new Color(0, 0, 0)));
        jLabel1.setText(bundle.getString("select file to encrypt"));
        jLabel2.setText(bundle.getString("choose certificate"));
        btnBrowse.setText(bundle.getString("btn.browse"));
        btnBrowse.addActionListener(this::btnBrowseActionPerformed);
        jLabel3.setText(bundle.getString("save file to"));
        btnBrowseSave.setText(bundle.getString("btn.browse"));
        btnBrowseSave.addActionListener(this::btnBrowseSaveActionPerformed);
        btnCancel.setText(bundle.getString("btn.cancel"));
        btnCancel.addActionListener(this::btnCancelActionPerformed);
        this.btnEncrypt.setText(bundle.getString("btn.encrypt"));
        this.btnEncrypt.addActionListener(this::btnEncryptActionPerformed);
        this.jtfCertificate.setEditable(false);
        btnSelectCertificate.setText(bundle.getString("btn.choose"));
        btnSelectCertificate.addActionListener(this::btnSelectCertificateActionPerformed);
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jSeparator1).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jLabel1).addComponent(jLabel2).addComponent(jLabel3)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.TRAILING).addComponent(this.jtfCertificate, GroupLayout.Alignment.LEADING, -1, 370, Short.MAX_VALUE).addComponent(this.jtfSaveFileTo).addComponent(this.jtfInputFile, GroupLayout.Alignment.LEADING)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, 8, -2).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(btnBrowse, GroupLayout.Alignment.TRAILING, -2, 70, -2).addComponent(btnSelectCertificate, GroupLayout.Alignment.TRAILING, -2, 70, -2).addComponent(btnBrowseSave, GroupLayout.Alignment.TRAILING, -2, 70, -2))).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(this.btnEncrypt).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnCancel))).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap(-1, Short.MAX_VALUE).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel1).addComponent(this.jtfInputFile, -2, -1, -2).addComponent(btnBrowse)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel2).addComponent(this.jtfCertificate, -2, -1, -2).addComponent(btnSelectCertificate)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel3).addComponent(this.jtfSaveFileTo, -2, -1, -2).addComponent(btnBrowseSave)).addGap(18, 18, 18).addComponent(jSeparator1, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnCancel).addComponent(this.btnEncrypt))));
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
            this.jtfInputFile.setText(jfc.getSelectedFile().toString());
            this.autoFillDestinationFile(this.jtfInputFile.getText());
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

    private void btnSelectCertificateActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, EncryptWithCertificateDialog.this.rbundle.getString("sign.progress.reading_certificates"));
                CertificateTableSelectorDialog csd = new CertificateTableSelectorDialog(null, true, true);
                csd.registerObserver(EncryptWithCertificateDialog.this.self);
                csd.setLocationRelativeTo(EncryptWithCertificateDialog.this.self);
                csd.setVisible(true);
                return null;
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
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
        if ("".equals(this.jtfCertificate.getText())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("sign.err_msg.certificateFieldEmpty"), this.rbundle.getString("sign.err_msg.certificateFieldEmpty"), 0);
            this.jtfSaveFileTo.requestFocus();
            return;
        }
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, EncryptWithCertificateDialog.this.rbundle.getString("encryptSym.settingParams"));
                EncryptFileAsymmetricInputModel encAsym = new EncryptFileAsymmetricInputModel();
                encAsym.setFilePath(EncryptWithCertificateDialog.this.jtfInputFile.getText());
                encAsym.setSaveFileTo(EncryptWithCertificateDialog.this.jtfSaveFileTo.getText());
                encAsym.setCertificate(EncryptWithCertificateDialog.this.selectedCertificate);
                this.firePropertyChange("currentOperation", null, EncryptWithCertificateDialog.this.rbundle.getString("encryptSym.encryptionOfTheFile"));
                EncryptClient ec = new EncryptClient();
                URI uri2 = ec.encryptAsymetricPost(encAsym);
                this.firePropertyChange("currentOperation", null, EncryptWithCertificateDialog.this.rbundle.getString("encryptSym.retreivingResults"));
                if (uri2 != null) {
                    EncryptDecryptFileResponseModel getResponse;
                    this.firePropertyChange("currentOperation", null, EncryptWithCertificateDialog.this.rbundle.getString("encrypt.progress.encryption_ok"));
                    try {
                        getResponse = ec.encryptAsymetricSymetricGet(uri2);
                    }
                    catch (ServerException ex) {
                        return new ProgressBarModel(EncryptWithCertificateDialog.this.rbundle.getString("sign.err_msg.sign_failed") + "\n" + ex.getMessage(), 0);
                    }
                    if (getResponse != null) {
                        this.setProgress(100);
                        EncryptWithCertificateDialog.this.cleanInputFields();
                        return new ProgressBarModel(EncryptWithCertificateDialog.this.rbundle.getString("encryption.ok"), 1);
                    }
                    return new ProgressBarModel(EncryptWithCertificateDialog.this.rbundle.getString("encrypt.err_msg.encrypt_failed"), 0);
                }
                return new ProgressBarModel(EncryptWithCertificateDialog.this.rbundle.getString("encrypt.err_msg.encrypt_failed"), 0);
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

    private void autoFillDestinationFile(String originalFileName) {
        if (originalFileName != null && !originalFileName.trim().isEmpty()) {
            String destinationFileName = originalFileName.concat(".msce");
            if (this.jtfSaveFileTo.getText().trim().isEmpty()) {
                this.jtfSaveFileTo.setText(destinationFileName);
            }
        }
    }

    public void setSelectedFile(String fileName) {
        this.jtfInputFile.setText(fileName);
        this.autoFillDestinationFile(this.jtfInputFile.getText());
    }
}

