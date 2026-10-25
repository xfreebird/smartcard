/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.popups;

import java.awt.Color;
import java.awt.Frame;
import java.awt.event.ActionEvent;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.msccm.models.CustomCertificatePopupTableModel;
import md.cts.moldsign.msccm.models.ProgressBarModel;
import md.cts.moldsign.msccm.observers.SelectCertificateObserver;
import md.cts.moldsign.msccm.popups.CertificateTableSelectorDialog;
import md.cts.moldsign.msccm.popups.ProgressBarDialog;
import md.cts.moldsign.msccm.rest.clients.SignFileClient;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.SignFileInputModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import md.ghesar.Resource;

public final class CounterSignDialog
extends JDialog
implements SelectCertificateObserver {
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    private final CounterSignDialog self = this;
    private final SignFileInputModel sfim;
    private CertificateModel selectedCertificate;
    private XadesSignatureModelContainer result;
    private JComboBox<String> cmbSignatureFormat;
    private JTextField jtfCertificate;

    public CounterSignDialog(Frame parent, boolean modal, SignFileInputModel sfim) {
        super(parent, modal);
        this.initComponents();
        this.sfim = sfim;
        this.cmbSignatureFormat.addItem("XAdES-BES");
        this.cmbSignatureFormat.addItem("XAdES-T");
        this.cmbSignatureFormat.addItem("XAdES-C");
    }

    private void initComponents() {
        this.setDefaultCloseOperation(2);
        JPanel jPanel4 = new JPanel();
        JLabel jLabel2 = new JLabel();
        JButton btnSignFile = new JButton();
        this.jtfCertificate = new JTextField();
        JButton browseCertificates = new JButton();
        JButton btnCancel = new JButton();
        JLabel lblSignatureFormat = new JLabel();
        this.cmbSignatureFormat = new JComboBox();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("title.sign_document"));
        this.setIconImage(Resource.getImage("/applogo.png"));
        jPanel4.setBorder(BorderFactory.createTitledBorder(null, "Sign document", 0, 0, null, new Color(0, 0, 0)));
        jLabel2.setText(bundle.getString("choose certificate"));
        btnSignFile.setText(bundle.getString("sign.btn.sign"));
        btnSignFile.addActionListener(this::btnSignFileActionPerformed);
        this.jtfCertificate.setEditable(false);
        browseCertificates.setText(bundle.getString("btn.choose"));
        browseCertificates.addActionListener(this::browseCertificatesActionPerformed);
        btnCancel.setText(bundle.getString("btn.cancel"));
        btnCancel.addActionListener(this::btnCancelActionPerformed);
        lblSignatureFormat.setLabelFor(this.cmbSignatureFormat);
        lblSignatureFormat.setText(bundle.getString("sign.lbl.sign_format"));
        GroupLayout jPanel4Layout = new GroupLayout(jPanel4);
        jPanel4.setLayout(jPanel4Layout);
        jPanel4Layout.setHorizontalGroup(jPanel4Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel4Layout.createSequentialGroup().addContainerGap().addGroup(jPanel4Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel4Layout.createSequentialGroup().addComponent(jLabel2).addGap(18, 18, 18).addComponent(this.jtfCertificate, -1, 316, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(browseCertificates)).addGroup(GroupLayout.Alignment.TRAILING, jPanel4Layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(btnSignFile).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(btnCancel)).addGroup(GroupLayout.Alignment.TRAILING, jPanel4Layout.createSequentialGroup().addComponent(lblSignatureFormat, -2, 104, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.cmbSignatureFormat, 0, -1, Short.MAX_VALUE))).addContainerGap()));
        jPanel4Layout.setVerticalGroup(jPanel4Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel4Layout.createSequentialGroup().addContainerGap(-1, Short.MAX_VALUE).addGroup(jPanel4Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jtfCertificate, -2, -1, -2).addComponent(browseCertificates).addComponent(jLabel2)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel4Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.cmbSignatureFormat, -2, -1, -2).addComponent(lblSignatureFormat)).addGap(18, 18, 18).addGroup(jPanel4Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnCancel).addComponent(btnSignFile)).addContainerGap()));
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel4, -1, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel4, -1, -1, Short.MAX_VALUE).addContainerGap()));
        jPanel4.getAccessibleContext().setAccessibleName(bundle.getString("title.sign_document"));
        this.pack();
    }

    private void btnSignFileActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, CounterSignDialog.this.rbundle.getString("sign.progress.setting_params"));
                CertificateModel cm = CounterSignDialog.this.selectedCertificate;
                CounterSignDialog.this.sfim.setCertificate(cm);
                CounterSignDialog.this.sfim.setSignFormat((String)CounterSignDialog.this.cmbSignatureFormat.getSelectedItem());
                SignFileClient sfc = new SignFileClient();
                this.firePropertyChange("currentOperation", null, CounterSignDialog.this.rbundle.getString("sign.progress.signing_file"));
                SignFileClient.Inter resp = sfc.signFilePost(CounterSignDialog.this.sfim, null);
                if (resp != null) {
                    try {
                        CounterSignDialog.this.result = sfc.signFileGet(resp.location(), false);
                    }
                    catch (ServerException ex) {
                        return new ProgressBarModel(CounterSignDialog.this.rbundle.getString("sign.err_msg.sign_failed") + "\n" + ex.getMessage(), 0);
                    }
                    if (CounterSignDialog.this.result != null) {
                        this.setProgress(100);
                        return new ProgressBarModel(CounterSignDialog.this.rbundle.getString("sign.succes.file_signed"), 1);
                    }
                    return new ProgressBarModel(CounterSignDialog.this.rbundle.getString("sign.err_msg.sign_failed"), 0);
                }
                return new ProgressBarModel(CounterSignDialog.this.rbundle.getString("sign.err_msg.sign_failed"), 0);
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
        this.dispose();
    }

    private void browseCertificatesActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, CounterSignDialog.this.rbundle.getString("sign.progress.reading_certificates"));
                CertificateTableSelectorDialog csd = new CertificateTableSelectorDialog(null, true);
                csd.registerObserver(CounterSignDialog.this.self);
                csd.setLocationRelativeTo(CounterSignDialog.this.self);
                csd.setVisible(true);
                return null;
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    private void btnCancelActionPerformed(ActionEvent evt) {
        this.dispose();
    }

    @Override
    public void onCertificateSelected(CertificateModel cm) {
        this.selectedCertificate = cm;
        this.jtfCertificate.setText(CustomCertificatePopupTableModel.getNameFromDN(this.selectedCertificate.getCertificate().getSubjectDN()));
    }

    public XadesSignatureModelContainer getResult() {
        return this.result;
    }
}

