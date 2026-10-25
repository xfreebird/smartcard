/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.panels;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.dnd.DropTarget;
import java.awt.event.ActionEvent;
import java.io.File;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import javax.swing.UIManager;
import javax.swing.table.DefaultTableModel;
import md.cts.moldsign.msccm.TabPanel;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.msccm.models.CustomCertificatePopupTableModel;
import md.cts.moldsign.msccm.models.FileDragDropListener;
import md.cts.moldsign.msccm.models.ProgressBarModel;
import md.cts.moldsign.msccm.observers.SelectCertificateObserver;
import md.cts.moldsign.msccm.popups.CertificateTableSelectorDialog;
import md.cts.moldsign.msccm.popups.FileExistsSelectAction;
import md.cts.moldsign.msccm.popups.ProgressBarDialog;
import md.cts.moldsign.msccm.rest.clients.SignFileClient;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.SignFileInputModel;
import md.cts.moldsign.transferobjects.models.SignPdfInputModel;
import md.cts.moldsign.transferobjects.models.SignPdfResponseModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import md.gov.stisc.AppProp;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SignMultipleFilesPanel
extends JPanel
implements TabPanel,
SelectCertificateObserver {
    private static final Logger logger = LoggerFactory.getLogger(SignMultipleFilesPanel.class);
    private final ResourceBundle resource = ResourceBundle.getBundle("translations");
    private final SignMultipleFilesPanel self;
    private final List<String> filesDocToPdf;
    private CertificateModel selectedCertificate;
    private SignFileInputModel sfim;
    private DefaultTableModel model;
    private XadesSignatureModelContainer result;
    private boolean pdfEnabled = true;
    private boolean xadesEmbededEnabled = true;
    private JButton btnSaveFileTo;
    private JCheckBox cbxSeaparate;
    private JComboBox<String> cmbSignatureAlgorithm;
    private JComboBox<String> cmbSignatureFormat;
    private JComboBox<String> cmbSignatureType;
    private JTextField jtfCertificate;
    private JTextField jtfSaveFileTo;
    private JTable tblFiles;

    public SignMultipleFilesPanel() {
        SignFileInputModel model = new SignFileInputModel();
        this.filesDocToPdf = new ArrayList<String>();
        this.self = this;
        this.sfim = model;
        this.initComponents();
        this.initTable();
        this.sfim = model;
        this.fillComponents();
    }

    private void initComponents() {
        JLabel jLabel2 = new JLabel();
        this.cmbSignatureFormat = new JComboBox();
        JLabel lblSignatureFormat = new JLabel();
        this.cmbSignatureType = new JComboBox();
        JLabel lblSignatureAlgorithm = new JLabel();
        this.cmbSignatureAlgorithm = new JComboBox();
        JLabel lblSignatureType = new JLabel();
        this.jtfCertificate = new JTextField();
        JButton browseCertificates = new JButton();
        JLabel jLabel3 = new JLabel();
        this.jtfSaveFileTo = new JTextField();
        JScrollPane jScrollPane1 = new JScrollPane();
        JButton btnRemoveFile = new JButton();
        this.cbxSeaparate = new JCheckBox();
        this.setAutoscrolls(true);
        jLabel2.setText(this.resource.getString("choose certificate"));
        lblSignatureFormat.setText(this.resource.getString("sign.lbl.sign_format"));
        lblSignatureAlgorithm.setText(this.resource.getString("sign.lbl.algorithm"));
        lblSignatureType.setText(this.resource.getString("sign.lbl.sign_type"));
        JPanel jPanel6 = new JPanel();
        jPanel6.setBorder(BorderFactory.createTitledBorder(null, this.resource.getString("sign.border.title.signFormat"), 0, 0, null, new Color(0, 0, 0)));
        GroupLayout jPanel6Layout = new GroupLayout(jPanel6);
        jPanel6.setLayout(jPanel6Layout);
        jPanel6Layout.setHorizontalGroup(jPanel6Layout.createSequentialGroup().addContainerGap().addComponent(lblSignatureFormat).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.cmbSignatureFormat).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED, -1, Short.MAX_VALUE).addComponent(lblSignatureAlgorithm).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.cmbSignatureAlgorithm).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED, -1, Short.MAX_VALUE).addComponent(lblSignatureType).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.cmbSignatureType).addContainerGap());
        jPanel6Layout.setVerticalGroup(jPanel6Layout.createSequentialGroup().addContainerGap().addGroup(jPanel6Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel6Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.cmbSignatureType).addComponent(this.cmbSignatureAlgorithm).addComponent(lblSignatureType)).addGroup(jPanel6Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.cmbSignatureFormat).addComponent(lblSignatureFormat).addComponent(lblSignatureAlgorithm))).addContainerGap());
        JButton btnSignFile = new JButton();
        btnSignFile.setForeground(Color.WHITE);
        btnSignFile.setBackground(new Color(76, 133, 33));
        btnSignFile.setPreferredSize(new Dimension(124, 48));
        btnSignFile.setText(this.resource.getString("sign.btn.sign"));
        Font fnt = btnSignFile.getFont();
        btnSignFile.setFont(new Font(fnt.getName(), fnt.getStyle(), (int)((double)fnt.getSize() * 1.4)));
        btnSignFile.addActionListener(this::btnSignFileActionPerformed);
        this.jtfCertificate.setEditable(false);
        browseCertificates.setText(this.resource.getString("btn.choose"));
        browseCertificates.addActionListener(this::browseCertificatesActionPerformed);
        jLabel3.setText(this.resource.getString("saveFileTo"));
        this.btnSaveFileTo = new JButton();
        this.btnSaveFileTo.setText(this.resource.getString("btn.browse"));
        this.btnSaveFileTo.addActionListener(this::btnSaveFileToActionPerformed);
        this.tblFiles = new JTable();
        this.tblFiles.setModel(new DefaultTableModel(new Object[0][], new String[]{"File Path"}));
        this.tblFiles.setFillsViewportHeight(true);
        jScrollPane1.setViewportView(this.tblFiles);
        btnRemoveFile.setText(this.resource.getString("btn.removefile"));
        btnRemoveFile.addActionListener(this::btnRemoveFileActionPerformed);
        JButton btnAddFile = new JButton();
        btnAddFile.setText(this.resource.getString("btn.addfile"));
        btnAddFile.addActionListener(this::btnAddFileActionPerformed);
        this.cbxSeaparate.setText(this.resource.getString("sign.signFilesSeparately"));
        this.cbxSeaparate.addActionListener(this::cbxSeparateActionPerformed);
        JPanel jPanel1 = new JPanel();
        jPanel1.setBorder(BorderFactory.createTitledBorder(null, this.resource.getString("title.border.addFilestoSign"), 0, 0, null, new Color(0, 0, 0)));
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.TRAILING).addComponent(jScrollPane1).addGroup(jPanel1Layout.createSequentialGroup().addComponent(this.cbxSeaparate).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, -1, Short.MAX_VALUE).addComponent(btnAddFile, -2, -2, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(btnRemoveFile))).addContainerGap());
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createSequentialGroup().addComponent(jScrollPane1, -1, 145, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnAddFile, -2, -2, -2).addComponent(btnRemoveFile).addComponent(this.cbxSeaparate)).addContainerGap());
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addComponent(jPanel6, -1, -1, Short.MAX_VALUE).addGroup(layout.createSequentialGroup().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jLabel2).addComponent(jLabel3)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jtfSaveFileTo).addComponent(this.jtfCertificate)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(browseCertificates, GroupLayout.Alignment.TRAILING).addComponent(this.btnSaveFileTo, GroupLayout.Alignment.TRAILING))).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(btnSignFile, -2, -2, -2))).addContainerGap());
        layout.setVerticalGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addGap(18, 18, 18).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel2).addComponent(this.jtfCertificate, -2, -1, -2).addComponent(browseCertificates)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel3).addComponent(this.jtfSaveFileTo, -2, -1, -2).addComponent(this.btnSaveFileTo)).addGap(18, 18, 18).addComponent(jPanel6, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(btnSignFile, -2, -2, -2).addContainerGap());
    }

    private void btnSignFileActionPerformed(ActionEvent evt) {
        if (this.tblFiles.getRowCount() < 1) {
            JOptionPane.showMessageDialog(this, this.resource.getString("sign.err_msg.please_select_file_to_sign"), this.resource.getString("sign.err_msg.please_select_file_to_sign"), 0);
            this.tblFiles.requestFocus();
            return;
        }
        if (this.jtfSaveFileTo.isEnabled() && this.jtfSaveFileTo.getText().trim().isEmpty()) {
            JOptionPane.showMessageDialog(this, this.resource.getString("sign.err_msg.save_signed_file_to"), this.resource.getString("sign.err_msg.save_signed_file_to"), 0);
            this.jtfSaveFileTo.requestFocus();
            return;
        }
        if (this.selectedCertificate == null) {
            SwingWorker<ProgressBarModel, String> swingWorker = new SwingWorker<ProgressBarModel, String>(){

                @Override
                protected ProgressBarModel doInBackground() {
                    this.firePropertyChange("currentOperation", null, SignMultipleFilesPanel.this.resource.getString("sign.progress.reading_certificates"));
                    CertificateTableSelectorDialog csd = new CertificateTableSelectorDialog(null, true);
                    csd.registerObserver(SignMultipleFilesPanel.this.self);
                    csd.setLocationRelativeTo(SignMultipleFilesPanel.this.self);
                    csd.setVisible(true);
                    return null;
                }
            };
            ProgressBarDialog progressBarDialog = new ProgressBarDialog(swingWorker);
            progressBarDialog.setLocationRelativeTo(this);
            progressBarDialog.setVisible(true);
        }
        SwingWorker<ProgressBarModel, String> worker = this.getApropriateWorker();
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    private void browseCertificatesActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, SignMultipleFilesPanel.this.resource.getString("sign.progress.reading_certificates"));
                CertificateTableSelectorDialog csd = new CertificateTableSelectorDialog(null, true);
                csd.registerObserver(SignMultipleFilesPanel.this.self);
                csd.setLocationRelativeTo(SignMultipleFilesPanel.this.self);
                csd.setVisible(true);
                return null;
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    private void btnSaveFileToActionPerformed(ActionEvent evt) {
        JFileChooser jfc = new JFileChooser();
        int dialogResult = jfc.showSaveDialog(this);
        if (dialogResult == 0) {
            String fileName = jfc.getSelectedFile().toString();
            ArrayList<String> filesToSign = new ArrayList<String>();
            for (int i = 0; i < this.tblFiles.getRowCount(); ++i) {
                Object object = this.model.getValueAt(i, 0);
                if (!(object instanceof String)) continue;
                filesToSign.add((String)object);
            }
            if (filesToSign.contains(fileName)) {
                JOptionPane.showMessageDialog(this, this.resource.getString("sign.err_msg.destination_sign_file_error"), this.resource.getString("sign.err_msg.destination_sign_file_error"), 0);
                this.jtfSaveFileTo.setText("");
            } else {
                this.jtfSaveFileTo.setText(fileName);
            }
        }
    }

    private void btnRemoveFileActionPerformed(ActionEvent evt) {
        int selectedRow = this.tblFiles.getSelectedRow();
        if (selectedRow != -1) {
            this.model.removeRow(selectedRow);
            this.model.fireTableDataChanged();
        } else {
            JOptionPane.showMessageDialog(this, this.resource.getString("sign.err_msg.please_select_file_to_remove"), this.resource.getString("sign.err_msg.please_select_file_to_remove"), 0);
        }
    }

    private void btnAddFileActionPerformed(ActionEvent evt) {
        int openDialogResponse;
        String wd;
        UIManager.put("FileChooser.readOnly", Boolean.TRUE);
        JFileChooser jfc = new JFileChooser();
        jfc.setAcceptAllFileFilterUsed(false);
        jfc.setMultiSelectionEnabled(true);
        Integer w = AppProp.getInt("sign.JFileChooser.w");
        Integer h = AppProp.getInt("sign.JFileChooser.h");
        if (w != null && h != null) {
            jfc.setPreferredSize(new Dimension(w, h));
        }
        if ((wd = AppProp.getStr("sign.JFileChooser.dir")) != null) {
            jfc.setCurrentDirectory(new File(wd));
        }
        if ((openDialogResponse = jfc.showOpenDialog(this)) == 0) {
            Dimension r = jfc.getSize();
            AppProp.setInt("sign.JFileChooser.w", r.width);
            AppProp.setInt("sign.JFileChooser.h", r.height);
            File dir = jfc.getCurrentDirectory();
            AppProp.setStr("sign.JFileChooser.dir", dir.getPath());
            for (File f : jfc.getSelectedFiles()) {
                this.model.addRow(new String[]{f.getAbsolutePath()});
                this.autoFillDestinationFile(jfc.getSelectedFile().getAbsolutePath());
            }
            this.model.fireTableDataChanged();
        }
    }

    private void cbxSeparateActionPerformed(ActionEvent evt) {
        if (this.cbxSeaparate.isSelected()) {
            this.jtfSaveFileTo.setText("");
        }
    }

    private void autoFillDestinationFile(String originalFile) {
        if (this.cbxSeaparate.isSelected()) {
            return;
        }
        if (originalFile != null && !originalFile.trim().isEmpty() && this.jtfSaveFileTo.getText() != null && this.jtfSaveFileTo.getText().trim().isEmpty()) {
            this.jtfSaveFileTo.setText(originalFile + ".xades");
        }
    }

    private void initTable() {
        this.model = new DefaultTableModel();
        this.model.addColumn("File path");
        this.model.addTableModelListener(e -> this.setSigningPossibilities());
        this.tblFiles.setModel(this.model);
        new DropTarget(this.tblFiles, new FileDragDropListener(this.model));
        this.cmbSignatureType.addItem("Detached");
        this.cmbSignatureType.addItem("Embedded");
        this.cmbSignatureAlgorithm.addItem("SHA-256");
        this.cmbSignatureFormat.addActionListener(e -> {
            String selectedFormat = (String)this.cmbSignatureFormat.getSelectedItem();
            if (selectedFormat == null) {
                return;
            }
            this.setSignatureType(selectedFormat);
        });
        this.cmbSignatureType.addActionListener(e -> {
            String selectedType = (String)this.cmbSignatureType.getSelectedItem();
            if ("Embedded".equals(selectedType)) {
                this.cbxSeaparate.setSelected(true);
                this.cbxSeaparate.setEnabled(false);
            } else {
                this.cbxSeaparate.setEnabled(true);
            }
        });
        this.cbxSeaparate.addChangeListener(e -> {
            this.jtfSaveFileTo.setEnabled(!this.cbxSeaparate.isSelected());
            this.btnSaveFileTo.setEnabled(!this.cbxSeaparate.isSelected());
        });
        this.setSigningPossibilities();
    }

    private void setSigningPossibilities() {
        this.pdfEnabled = true;
        this.xadesEmbededEnabled = true;
        for (int i = 0; i < this.model.getRowCount(); ++i) {
            File f;
            if (this.model.getValueAt(i, 0) instanceof String && this.model.getValueAt(i, 0) == null) continue;
            String fileName = (String)this.model.getValueAt(i, 0);
            if (!fileName.trim().toLowerCase().endsWith("pdf")) {
                this.pdfEnabled = false;
            }
            if ((f = new File(fileName)).length() <= 102400L) continue;
            this.xadesEmbededEnabled = false;
        }
        this.correctSigningOptions();
    }

    private void correctSigningOptions() {
        ArrayList<String> possibleFormatValues = new ArrayList<String>();
        if (this.pdfEnabled) {
            possibleFormatValues.add("PAdES-T");
        }
        possibleFormatValues.add("XAdES-T");
        possibleFormatValues.add("XAdES-BES");
        possibleFormatValues.add("XAdES-C");
        this.cmbSignatureFormat.removeAllItems();
        for (String item : possibleFormatValues) {
            this.cmbSignatureFormat.addItem(item);
        }
    }

    private void setSignatureType(String selectedFormat) {
        if ("PAdES".equals(selectedFormat) || "PAdES-T".equals(selectedFormat)) {
            this.cmbSignatureType.setSelectedItem("Embedded");
            this.cmbSignatureType.setEnabled(false);
        } else if (this.xadesEmbededEnabled) {
            this.cmbSignatureType.setEnabled(true);
        } else {
            this.cmbSignatureType.setSelectedItem("Detached");
            this.cmbSignatureType.setEnabled(false);
        }
    }

    private void fillComponents() {
        if (this.sfim.getDestinationFile() != null) {
            this.jtfSaveFileTo.setText(this.sfim.getDestinationFile());
        }
        if (this.sfim.getFilesToSign() != null) {
            for (String str : this.sfim.getFilesToSign()) {
                this.model.addRow(new String[]{str});
                this.autoFillDestinationFile(str);
            }
            this.model.fireTableDataChanged();
        }
    }

    @Override
    public void onCertificateSelected(CertificateModel cm) {
        this.selectedCertificate = cm;
        this.jtfCertificate.setText(CustomCertificatePopupTableModel.getNameFromDN(this.selectedCertificate.getCertificate().getSubjectDN()));
    }

    private SwingWorker<ProgressBarModel, String> getApropriateWorker() {
        this.filesDocToPdf.clear();
        SwingWorker worker = "XAdES-BES".equals(this.cmbSignatureFormat.getSelectedItem()) || "XAdES-T".equals(this.cmbSignatureFormat.getSelectedItem()) || "XAdES-C".equals(this.cmbSignatureFormat.getSelectedItem()) ? (this.cbxSeaparate.isSelected() ? new XadesMulitpleSignatureWorker() : new XadesSingleSignatureWorker()) : new PdfSigningWorker();
        return worker;
    }

    @Override
    public void setSelectedFile(String action, String fileName) {
        this.model.addRow(new String[]{fileName});
        this.autoFillDestinationFile(fileName);
        this.model.fireTableDataChanged();
    }

    private void checkDestFileAlreadyExists(String destFileName) {
        File destFile = new File(destFileName);
        if (destFile.exists()) {
            FileExistsSelectAction fesa = new FileExistsSelectAction(destFile.getName());
            fesa.setLocationRelativeTo(this);
            fesa.setVisible(true);
            if (FileExistsSelectAction.Action.OVERWRITE.equals((Object)fesa.getResult())) {
                boolean ok = destFile.delete();
                logger.info("delete exists={}", (Object)ok);
            }
        }
    }

    private class XadesMulitpleSignatureWorker
    extends SwingWorker<ProgressBarModel, String> {
        private XadesMulitpleSignatureWorker() {
        }

        @Override
        protected ProgressBarModel doInBackground() {
            this.firePropertyChange("currentOperation", null, SignMultipleFilesPanel.this.resource.getString("sign.progress.setting_params"));
            ArrayList<String> filesToSign = new ArrayList<String>();
            CertificateModel cm = SignMultipleFilesPanel.this.selectedCertificate;
            SignMultipleFilesPanel.this.sfim.setDestinationFile(SignMultipleFilesPanel.this.jtfSaveFileTo.getText());
            SignMultipleFilesPanel.this.sfim.setCertificate(cm);
            SignMultipleFilesPanel.this.sfim.setSignFormat((String)SignMultipleFilesPanel.this.cmbSignatureFormat.getSelectedItem());
            SignMultipleFilesPanel.this.sfim.setType((String)SignMultipleFilesPanel.this.cmbSignatureType.getSelectedItem());
            SignMultipleFilesPanel.this.sfim.setSignAlgorithm((String)SignMultipleFilesPanel.this.cmbSignatureAlgorithm.getSelectedItem());
            SignFileClient sfc = new SignFileClient();
            int nrFilesToSign = SignMultipleFilesPanel.this.tblFiles.getRowCount();
            ArrayList<Integer> filesToRemove = new ArrayList<Integer>(nrFilesToSign);
            String previousSession = null;
            for (int i = 0; i < nrFilesToSign; ++i) {
                Object object = SignMultipleFilesPanel.this.model.getValueAt(i, 0);
                String fileName = "";
                if (object instanceof String) {
                    fileName = (String)object;
                }
                filesToSign.clear();
                filesToSign.add(fileName);
                this.firePropertyChange("currentOperation", null, SignMultipleFilesPanel.this.resource.getString("sign.progress.signing_file") + " : " + fileName);
                SignMultipleFilesPanel.this.sfim.setFilesToSign(filesToSign);
                String destFileName = fileName + ".xades";
                SignMultipleFilesPanel.this.checkDestFileAlreadyExists(destFileName);
                SignMultipleFilesPanel.this.sfim.setDestinationFile(destFileName);
                SignMultipleFilesPanel.this.sfim.setSignatureFile(destFileName);
                SignFileClient.Inter resp = sfc.signFilePost(SignMultipleFilesPanel.this.sfim, previousSession);
                this.setProgress(i / nrFilesToSign);
                if (resp == null) continue;
                if (previousSession == null) {
                    previousSession = resp.sessionId();
                }
                try {
                    SignMultipleFilesPanel.this.result = sfc.signFileGet(resp.location(), i < nrFilesToSign - 1);
                }
                catch (ServerException ex) {
                    logger.error("", (Throwable)ex);
                }
                if (SignMultipleFilesPanel.this.result == null) continue;
                filesToRemove.add(i);
            }
            int nrFilesSignedSuccess = filesToRemove.size();
            int nrFilesSignedProblem = nrFilesToSign - nrFilesSignedSuccess;
            this.setProgress(100);
            for (int j = filesToRemove.size() - 1; j >= 0; --j) {
                int nrFile = (Integer)filesToRemove.get(j);
                SignMultipleFilesPanel.this.model.removeRow(nrFile);
            }
            SignMultipleFilesPanel.this.model.fireTableDataChanged();
            String report = SignMultipleFilesPanel.this.resource.getString("sign.multiple.report");
            report = MessageFormat.format(report, nrFilesToSign, nrFilesSignedSuccess, nrFilesSignedProblem);
            return new ProgressBarModel(report, 1);
        }
    }

    private class XadesSingleSignatureWorker
    extends SwingWorker<ProgressBarModel, String> {
        private XadesSingleSignatureWorker() {
        }

        @Override
        protected ProgressBarModel doInBackground() {
            this.firePropertyChange("currentOperation", null, SignMultipleFilesPanel.this.resource.getString("sign.progress.setting_params"));
            ArrayList<String> filesToSign = new ArrayList<String>();
            for (int i = 0; i < SignMultipleFilesPanel.this.tblFiles.getRowCount(); ++i) {
                Object object = SignMultipleFilesPanel.this.model.getValueAt(i, 0);
                if (!(object instanceof String)) continue;
                filesToSign.add((String)object);
            }
            CertificateModel cm = SignMultipleFilesPanel.this.selectedCertificate;
            String destFileName = SignMultipleFilesPanel.this.jtfSaveFileTo.getText();
            SignMultipleFilesPanel.this.checkDestFileAlreadyExists(destFileName);
            SignMultipleFilesPanel.this.sfim.setDestinationFile(destFileName);
            SignMultipleFilesPanel.this.sfim.setSignatureFile(destFileName);
            SignMultipleFilesPanel.this.sfim.setCertificate(cm);
            SignMultipleFilesPanel.this.sfim.setFilesToSign(filesToSign);
            SignMultipleFilesPanel.this.sfim.setSignFormat((String)SignMultipleFilesPanel.this.cmbSignatureFormat.getSelectedItem());
            SignFileClient sfc = new SignFileClient();
            this.firePropertyChange("currentOperation", null, SignMultipleFilesPanel.this.resource.getString("sign.progress.signing_file"));
            SignFileClient.Inter resp = sfc.signFilePost(SignMultipleFilesPanel.this.sfim, null);
            if (resp != null) {
                try {
                    SignMultipleFilesPanel.this.result = sfc.signFileGet(resp.location(), false);
                }
                catch (ServerException ex) {
                    return new ProgressBarModel(SignMultipleFilesPanel.this.resource.getString("sign.err_msg.sign_failed") + "\n" + ex.getMessage(), 0);
                }
                if (SignMultipleFilesPanel.this.result != null) {
                    this.setProgress(100);
                    return new ProgressBarModel(SignMultipleFilesPanel.this.resource.getString("sign.succes.file_signed"), 1);
                }
                return new ProgressBarModel(SignMultipleFilesPanel.this.resource.getString("sign.err_msg.sign_failed"), 0);
            }
            return new ProgressBarModel(SignMultipleFilesPanel.this.resource.getString("sign.err_msg.sign_failed"), 0);
        }
    }

    private class PdfSigningWorker
    extends SwingWorker<ProgressBarModel, String> {
        private PdfSigningWorker() {
        }

        @Override
        protected ProgressBarModel doInBackground() {
            SignPdfInputModel spim = new SignPdfInputModel();
            this.firePropertyChange("currentOperation", null, SignMultipleFilesPanel.this.resource.getString("sign.progress.setting_params"));
            spim.setCertificate(SignMultipleFilesPanel.this.selectedCertificate);
            spim.setFormat((String)SignMultipleFilesPanel.this.cmbSignatureFormat.getSelectedItem());
            spim.setAlgorithm((String)SignMultipleFilesPanel.this.cmbSignatureAlgorithm.getSelectedItem());
            int nrFilesToSign = SignMultipleFilesPanel.this.tblFiles.getRowCount();
            ArrayList<Integer> filesToRemove = new ArrayList<Integer>(nrFilesToSign);
            String defaultSession = null;
            for (int i = 0; i < nrFilesToSign; ++i) {
                Object object = SignMultipleFilesPanel.this.model.getValueAt(i, 0);
                String fileName = "";
                if (object instanceof String) {
                    fileName = (String)object;
                }
                spim.setOriginalFile(fileName);
                String destFileName = this.getDestinationFileName(fileName);
                SignMultipleFilesPanel.this.checkDestFileAlreadyExists(destFileName);
                spim.setSignedFile(destFileName);
                SignFileClient sfc = new SignFileClient();
                this.firePropertyChange("currentOperation", null, SignMultipleFilesPanel.this.resource.getString("sign.progress.signing_file"));
                SignFileClient.Inter resp = sfc.signPdfPost(spim, defaultSession);
                this.setProgress(i / nrFilesToSign);
                if (resp != null) {
                    SignPdfResponseModel signPdfGet = null;
                    try {
                        signPdfGet = sfc.signPdfGet(resp.location(), i < nrFilesToSign - 1);
                    }
                    catch (ServerException ex) {
                        logger.error("", (Throwable)ex);
                    }
                    String previousSession = resp.sessionId();
                    if (defaultSession == null) {
                        defaultSession = previousSession;
                    }
                    if (signPdfGet == null) continue;
                    filesToRemove.add(i);
                    continue;
                }
                return new ProgressBarModel(SignMultipleFilesPanel.this.resource.getString("sign.err_msg.sign_failed"), 0);
            }
            int nrFilesSignedSuccess = filesToRemove.size();
            int nrFilesSignedProblem = nrFilesToSign - nrFilesSignedSuccess;
            this.setProgress(100);
            for (int j = filesToRemove.size() - 1; j >= 0; --j) {
                int nrFile = (Integer)filesToRemove.get(j);
                SignMultipleFilesPanel.this.model.removeRow(nrFile);
            }
            SignMultipleFilesPanel.this.model.fireTableDataChanged();
            String report = SignMultipleFilesPanel.this.resource.getString("sign.multiple.report");
            report = MessageFormat.format(report, nrFilesToSign, nrFilesSignedSuccess, nrFilesSignedProblem);
            if (!SignMultipleFilesPanel.this.filesDocToPdf.isEmpty()) {
                for (String fineName : SignMultipleFilesPanel.this.filesDocToPdf) {
                    File file = new File(fineName);
                    boolean ok = file.delete();
                    logger.info("delete={}", (Object)ok);
                }
            }
            return new ProgressBarModel(report, 1);
        }

        private String getDestinationFileName(String originalName) {
            String newFileName = "";
            if (originalName != null && !originalName.trim().isEmpty()) {
                int fileExtensionStart = originalName.lastIndexOf(".");
                newFileName = fileExtensionStart < 0 ? originalName : originalName.substring(0, fileExtensionStart);
                newFileName = newFileName.concat(".signed.pdf");
            }
            return newFileName;
        }
    }
}

