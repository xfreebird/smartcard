/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.jce.provider.BouncyCastleProvider
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.panels;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Desktop;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Window;
import java.awt.dnd.DropTarget;
import java.awt.event.ActionEvent;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.OpenOption;
import java.security.Provider;
import java.security.Security;
import java.security.cert.CertificateEncodingException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTree;
import javax.swing.LayoutStyle;
import javax.swing.SwingUtilities;
import javax.swing.SwingWorker;
import javax.swing.UIManager;
import javax.swing.event.TreeSelectionEvent;
import javax.swing.event.TreeSelectionListener;
import javax.swing.filechooser.FileNameExtensionFilter;
import javax.swing.tree.DefaultTreeCellRenderer;
import md.cts.moldsign.ghesar.PdfFile;
import md.cts.moldsign.ghesar.SigInfoDialog;
import md.cts.moldsign.msccm.TabPanel;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.msccm.models.CustomSignatureModel;
import md.cts.moldsign.msccm.models.ProgressBarModel;
import md.cts.moldsign.msccm.models.SignaturesTableModel;
import md.cts.moldsign.msccm.models.VerifyDropListener;
import md.cts.moldsign.msccm.panels.DetailsCertInfoTab;
import md.cts.moldsign.msccm.panels.PdfFileTableModel;
import md.cts.moldsign.msccm.popups.CounterSignDialog;
import md.cts.moldsign.msccm.popups.ProgressBarDialog;
import md.cts.moldsign.msccm.rest.clients.SignaturesClient;
import md.cts.moldsign.msccm.rest.clients.VerifyFileClient;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.DeleteSignatureInputModel;
import md.cts.moldsign.transferobjects.models.SignFileInputModel;
import md.cts.moldsign.transferobjects.models.VerifySignedFileInputModel;
import md.cts.moldsign.transferobjects.models.VerifySignedFileResponseModel;
import md.cts.moldsign.transferobjects.models.XAdES.GetSignatureFileInputModel;
import md.cts.moldsign.transferobjects.models.XAdES.SigningReferenceModel;
import md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import md.ghesar.Resource;
import md.gov.stisc.AppProp;
import md.gov.stisc.Single;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SignatureInfoPanel
extends JPanel
implements TabPanel,
TreeSelectionListener {
    private static final Logger logger = LoggerFactory.getLogger(SignatureInfoPanel.class);
    private final ResourceBundle resource = ResourceBundle.getBundle("translations");
    private final Window parentWindow;
    private PdfFile pdfFile = null;
    private CustomSignatureModel customSignatureModel;
    private DetailsCertInfoTab dcit;
    private SignaturesTableModel xadesTableModel;
    private XAdESSignatureModel selectedSignature = null;
    private String signatureFile;
    private PdfFileTableModel pdfFileTableModel;
    private MouseListener pdfFileTableListener;
    private JButton btnAddFiles;
    private JButton buttonRemove;
    private JPanel uiPanelFileSigned;
    private JPanel uiPanelSignatures;
    private JPanel uiPanelSignatureInfo;
    private JTree uiSignaturesTree;
    private JTable uiPdfFileTable;
    private boolean isUiInit = true;
    private GroupLayout layoutXad;
    private GroupLayout layoutVeri;

    public SignatureInfoPanel(Window parent) {
        this.parentWindow = parent;
        this.initComponents();
        this.setupTree();
    }

    private void initComponents() {
        JButton btnVerifySignature = new JButton();
        JButton btnCoSign = new JButton();
        JButton btnCounterSign = new JButton();
        JButton btnDeleteSignature = new JButton();
        btnVerifySignature.setText(this.resource.getString("btn.verifysignature"));
        btnVerifySignature.addActionListener(this::btnVerifySignatureActionPerformed);
        btnCoSign.setText(this.resource.getString("btn.co-sign"));
        btnCoSign.addActionListener(this::btnCoSignActionPerformed);
        btnCounterSign.setText(this.resource.getString("btn.counter-signature"));
        btnCounterSign.addActionListener(this::btnCounterSignActionPerformed);
        btnDeleteSignature.setText(this.resource.getString("btn.deletesignature"));
        btnDeleteSignature.addActionListener(this::btnDeleteSignatureActionPerformed);
        this.uiPanelFileSigned = new JPanel();
        this.uiPanelFileSigned.setBorder(BorderFactory.createTitledBorder(null, this.resource.getString("border.title.filesSigned"), 0, 0, new Font("Dialog", 1, 12), new Color(0, 0, 0)));
        this.uiPanelFileSigned.setEnabled(false);
        this.uiPdfFileTable = new JTable();
        this.uiPdfFileTable.setFillsViewportHeight(true);
        JScrollPane scrollPanePdfFile = new JScrollPane();
        scrollPanePdfFile.setViewportView(this.uiPdfFileTable);
        this.btnAddFiles = new JButton();
        this.btnAddFiles.setText(this.resource.getString("btn.setPath"));
        this.btnAddFiles.setVisible(false);
        this.btnAddFiles.addActionListener(this::btnAddFilesActionPerformed);
        this.buttonRemove = new JButton();
        this.buttonRemove.setText(this.resource.getString("pdfverify.button.remove"));
        this.buttonRemove.setVisible(false);
        String[] pathHeaders = new String[]{this.resource.getString("pdfverify.pathcolumn.name"), this.resource.getString("pdfverify.pathcolumn.path")};
        this.pdfFileTableModel = new PdfFileTableModel(pathHeaders);
        this.xadesTableModel = new SignaturesTableModel();
        this.uiPdfFileTable.setModel(this.xadesTableModel);
        this.pdfFileTableListener = new MouseAdapter(){

            @Override
            public void mouseClicked(MouseEvent ev) {
                String tempPath;
                boolean ok;
                int row;
                if (ev.getClickCount() == 1 && (row = SignatureInfoPanel.this.uiPdfFileTable.rowAtPoint(ev.getPoint())) != -1 && (ok = SignatureInfoPanel.this.loadPdfSignatures(tempPath = SignatureInfoPanel.this.pdfFileTableModel.getRow(row))) && SignatureInfoPanel.this.pdfFile != null) {
                    SwingUtilities.invokeLater(() -> SigInfoDialog.show(SignatureInfoPanel.this.parentWindow, SignatureInfoPanel.this.pdfFile));
                }
            }
        };
        new DropTarget(this.uiPdfFileTable, 1, new VerifyDropListener(this::addVerifyFile), true, null);
        GroupLayout jPanel1Layout = new GroupLayout(this.uiPanelFileSigned);
        this.uiPanelFileSigned.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.TRAILING).addComponent(scrollPanePdfFile, -1, 637, Short.MAX_VALUE).addGroup(jPanel1Layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(this.buttonRemove).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.btnAddFiles))).addContainerGap());
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addComponent(scrollPanePdfFile, -1, 101, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.btnAddFiles).addComponent(this.buttonRemove)));
        this.uiPanelSignatures = new JPanel();
        this.uiPanelSignatures.setBorder(BorderFactory.createTitledBorder(null, this.resource.getString("title.border.signatures"), 0, 0, new Font("Dialog", 1, 12), new Color(0, 0, 0)));
        this.uiPanelSignatures.setEnabled(false);
        JScrollPane jScrollPane2 = new JScrollPane();
        jScrollPane2.setMaximumSize(new Dimension(300, 150));
        jScrollPane2.setPreferredSize(new Dimension(300, 502));
        this.uiSignaturesTree = new JTree();
        this.uiSignaturesTree.setModel(this.customSignatureModel);
        this.uiSignaturesTree.setMaximumSize(new Dimension(250, 100));
        this.uiSignaturesTree.setRowHeight(25);
        this.uiSignaturesTree.addMouseListener(new MouseAdapter(){

            @Override
            public void mousePressed(MouseEvent evt) {
                SignatureInfoPanel.this.onMousePressed(evt);
            }
        });
        jScrollPane2.setViewportView(this.uiSignaturesTree);
        GroupLayout jPanel2Layout = new GroupLayout(this.uiPanelSignatures);
        this.uiPanelSignatures.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel2Layout.createSequentialGroup().addContainerGap().addGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel2Layout.createSequentialGroup().addGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.LEADING, false).addComponent(jScrollPane2, -2, -1, -2).addGroup(GroupLayout.Alignment.TRAILING, jPanel2Layout.createSequentialGroup().addComponent(btnCounterSign, -1, -1, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(btnCoSign, -2, 138, -2))).addGap(0, 0, Short.MAX_VALUE)).addGroup(jPanel2Layout.createSequentialGroup().addComponent(btnVerifySignature, -2, 156, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, -1, Short.MAX_VALUE).addComponent(btnDeleteSignature, -2, 138, -2))).addContainerGap()));
        jPanel2Layout.setVerticalGroup(jPanel2Layout.createSequentialGroup().addComponent(jScrollPane2, -2, 0, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnVerifySignature).addComponent(btnDeleteSignature)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnCounterSign).addComponent(btnCoSign)).addContainerGap());
        this.uiPanelSignatureInfo = new JPanel();
        this.uiPanelSignatureInfo.setBorder(BorderFactory.createTitledBorder(null, this.resource.getString("title.border.info"), 0, 0, new Font("Dialog", 1, 12), new Color(0, 0, 0)));
        this.uiPanelSignatureInfo.setEnabled(false);
        this.uiPanelSignatureInfo.setMinimumSize(new Dimension(200, 30));
        this.uiPanelSignatureInfo.setLayout(new BorderLayout());
        JButton btnCleanFile = new JButton();
        btnCleanFile.setText(this.resource.getString("btn.clean"));
        btnCleanFile.addActionListener(e -> {
            this.customSignatureModel = null;
            this.dcit = null;
            this.uiSignaturesTree.setModel(null);
            this.uiSignaturesTree.removeAll();
            this.xadesTableModel.clear();
            this.xadesTableModel.fireTableDataChanged();
            this.uiPanelSignatureInfo.removeAll();
            this.pdfFileTableModel.clear();
            this.uiPdfFileTable.repaint();
            this.uiSignaturesTree.repaint();
            this.uiPanelSignatureInfo.repaint();
        });
        JButton btnSelectFile = new JButton();
        btnSelectFile.setText(this.resource.getString("btn.browse"));
        btnSelectFile.addActionListener(this::onClickBtnSelectFile);
        this.layoutXad = new GroupLayout(this);
        this.setLayout(this.layoutXad);
        this.layoutXad.setHorizontalGroup(this.layoutXad.createSequentialGroup().addContainerGap().addGroup(this.layoutXad.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(this.layoutXad.createSequentialGroup().addComponent(this.uiPanelSignatures, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.uiPanelSignatureInfo, -1, -1, Short.MAX_VALUE)).addComponent(this.uiPanelFileSigned, -1, -1, Short.MAX_VALUE).addGroup(GroupLayout.Alignment.TRAILING, this.layoutXad.createSequentialGroup().addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnSelectFile).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnCleanFile).addContainerGap())).addContainerGap());
        this.layoutXad.setVerticalGroup(this.layoutXad.createSequentialGroup().addContainerGap().addGroup(this.layoutXad.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnSelectFile).addComponent(btnCleanFile)).addComponent(this.uiPanelFileSigned, -2, -2, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(this.layoutXad.createParallelGroup(GroupLayout.Alignment.TRAILING).addComponent(this.uiPanelSignatureInfo, -1, -1, Short.MAX_VALUE).addComponent(this.uiPanelSignatures, -1, -1, Short.MAX_VALUE)).addContainerGap());
        this.layoutVeri = new GroupLayout(this);
        this.layoutVeri.setHorizontalGroup(this.layoutVeri.createSequentialGroup().addContainerGap().addGroup(this.layoutVeri.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.uiPanelFileSigned, -1, -1, Short.MAX_VALUE).addGroup(GroupLayout.Alignment.TRAILING, this.layoutVeri.createSequentialGroup().addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnSelectFile).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnCleanFile).addContainerGap())).addContainerGap());
        this.layoutVeri.setVerticalGroup(this.layoutVeri.createSequentialGroup().addContainerGap().addGroup(this.layoutVeri.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnSelectFile).addComponent(btnCleanFile)).addComponent(this.uiPanelFileSigned, -2, -2, Short.MAX_VALUE).addGap(10).addContainerGap());
    }

    private void btnAddFilesActionPerformed(ActionEvent evt) {
        int selectedRow = this.uiPdfFileTable.getSelectedRow();
        if (selectedRow != -1) {
            JFileChooser jfc = new JFileChooser();
            jfc.setAcceptAllFileFilterUsed(false);
            int result = jfc.showOpenDialog(this);
            if (result == 0) {
                this.xadesTableModel.getReferenceAt(selectedRow).setPath(jfc.getSelectedFile().getAbsolutePath());
                this.xadesTableModel.fireTableDataChanged();
            }
        } else {
            JOptionPane.showMessageDialog(this, this.resource.getString("nosfilepathselected"), this.resource.getString("nosfilepathselected"), 0);
        }
    }

    private void btnVerifySignatureActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, SignatureInfoPanel.this.resource.getString("sign.progress.setting_params"));
                VerifySignedFileInputModel vsfim = new VerifySignedFileInputModel();
                vsfim.setSignature(SignatureInfoPanel.this.signatureFile);
                if (SignatureInfoPanel.this.selectedSignature == null || SignatureInfoPanel.this.selectedSignature.getId() == null) {
                    return new ProgressBarModel(SignatureInfoPanel.this.resource.getString("sign.err_msg.please_select_signature"), 0);
                }
                vsfim.setSignatureId(SignatureInfoPanel.this.selectedSignature.getId());
                ArrayList<String> filePaths = new ArrayList<String>();
                for (int i = 0; i < SignatureInfoPanel.this.uiPdfFileTable.getRowCount(); ++i) {
                    SigningReferenceModel srm = SignatureInfoPanel.this.xadesTableModel.getReferenceAt(i);
                    if (srm == null || srm.getPath() == null || srm.getPath().trim().isEmpty()) {
                        return new ProgressBarModel(SignatureInfoPanel.this.resource.getString("sign.err_msg.please_set_paths_for_files_to_sign"), 0);
                    }
                    filePaths.add(srm.getPath().trim());
                }
                vsfim.setSignedFiles(filePaths);
                VerifyFileClient vfc = new VerifyFileClient();
                URI uri2 = vfc.verifySignedFilePost(vsfim);
                if (uri2 != null) {
                    VerifySignedFileResponseModel vsfrm;
                    try {
                        vsfrm = vfc.verifySignedFileGet(uri2);
                    }
                    catch (ServerException ex) {
                        return new ProgressBarModel(SignatureInfoPanel.this.resource.getString("sign.err_msg.sign_failed") + "\n" + ex.getMessage(), 0);
                    }
                    if (vsfrm != null && vsfrm.isValid()) {
                        return new ProgressBarModel(SignatureInfoPanel.this.resource.getString("signature.valid"), 1);
                    }
                }
                return new ProgressBarModel(SignatureInfoPanel.this.resource.getString("signature.invalid"), 0);
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    private void btnCoSignActionPerformed(ActionEvent evt) {
        SignFileInputModel sfim = new SignFileInputModel();
        if (this.customSignatureModel == null) {
            logger.warn("customSignatureModel == null");
            return;
        }
        XAdESSignatureModel xmodel = this.customSignatureModel.getParent(this.selectedSignature);
        if (xmodel != null) {
            sfim.setSignatureReference(xmodel.getId());
        }
        ArrayList<String> filePaths = new ArrayList<String>();
        sfim.setSignatureFile(this.signatureFile);
        sfim.setDestinationFile(this.signatureFile);
        for (int i = 0; i < this.uiPdfFileTable.getRowCount(); ++i) {
            SigningReferenceModel srm = this.xadesTableModel.getReferenceAt(i);
            if (srm == null || srm.getPath() == null || srm.getPath().trim().isEmpty()) {
                JOptionPane.showMessageDialog(this, this.resource.getString("sign.err_msg.please_set_paths_for_files_to_sign"), this.resource.getString("sign.err_msg.please_set_paths_for_files_to_sign"), 0);
                this.uiPdfFileTable.requestFocus();
                return;
            }
            filePaths.add(srm.getPath().trim());
        }
        if (this.uiPdfFileTable.getRowCount() == 0) {
            filePaths.add(this.signatureFile);
            sfim.setFilesToSign(filePaths);
        }
        sfim.setFilesToSign(filePaths);
        CounterSignDialog nsmfd = new CounterSignDialog(null, true, sfim);
        nsmfd.setLocationRelativeTo(this);
        nsmfd.setVisible(true);
        XadesSignatureModelContainer result = nsmfd.getResult();
        if (result != null) {
            this.loadSignatures(result);
        }
    }

    private void btnCounterSignActionPerformed(ActionEvent evt) {
        SignFileInputModel sfim = new SignFileInputModel();
        XAdESSignatureModel xmodel = this.selectedSignature;
        if (xmodel == null) {
            JOptionPane.showMessageDialog(this, this.resource.getString("sign.err_msg.please_select_signature_to_counter-sign"), this.resource.getString("sign.err_msg.please_select_signature_to_counter-sign"), 0);
            this.uiPdfFileTable.requestFocus();
            return;
        }
        sfim.setSignatureReference(xmodel.getId());
        ArrayList<String> filePaths = new ArrayList<String>();
        sfim.setSignatureFile(this.signatureFile);
        sfim.setDestinationFile(this.signatureFile);
        for (int i = 0; i < this.uiPdfFileTable.getRowCount(); ++i) {
            SigningReferenceModel srm = this.xadesTableModel.getReferenceAt(i);
            if (srm == null || srm.getPath() == null || srm.getPath().trim().isEmpty()) {
                JOptionPane.showMessageDialog(this, this.resource.getString("sign.err_msg.please_set_paths_for_files_to_sign"), this.resource.getString("sign.err_msg.please_set_paths_for_files_to_sign"), 0);
                this.uiPdfFileTable.requestFocus();
                return;
            }
            filePaths.add(srm.getPath().trim());
        }
        sfim.setFilesToSign(filePaths);
        CounterSignDialog nsmfd = new CounterSignDialog(null, true, sfim);
        nsmfd.setLocationRelativeTo(this);
        nsmfd.setVisible(true);
        XadesSignatureModelContainer result = nsmfd.getResult();
        if (result != null) {
            this.loadSignatures(result);
        }
    }

    private void btnDeleteSignatureActionPerformed(ActionEvent evt) {
        if (this.selectedSignature == null) {
            JOptionPane.showMessageDialog(this, this.resource.getString("sign.err_msg.please_select_signature"), this.resource.getString("sign.err_msg.please_select_signature"), 0);
            this.uiSignaturesTree.requestFocus();
            return;
        }
        if (this.selectedSignature.getCounterSignatures() != null && !this.selectedSignature.getCounterSignatures().isEmpty()) {
            JOptionPane.showMessageDialog(this, this.resource.getString("delete_signature.cannotdelete.notempty"), this.resource.getString("delete_signature.cannotdelete.title"), 0);
            this.uiSignaturesTree.requestFocus();
            return;
        }
        if (this.customSignatureModel.getSignatures() != null && this.customSignatureModel.getSignatures().size() <= 1 && this.customSignatureModel.getSignatures().get(0).getCounterSignatures() == null) {
            JOptionPane.showMessageDialog(this, this.resource.getString("delete_signature.cannotdelete.onlyone"), this.resource.getString("delete_signature.cannotdelete.title"), 0);
            this.uiSignaturesTree.requestFocus();
            return;
        }
        int result = JOptionPane.showConfirmDialog(this, this.resource.getString("confirm.message.deletesignature"), this.resource.getString("confirm.message.deletesignature.title"), 0);
        if (result == 0) {
            ProgressBarDialog pbd = this.getProgressBarDialog();
            pbd.setLocationRelativeTo(this);
            pbd.setVisible(true);
        }
    }

    private ProgressBarDialog getProgressBarDialog() {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                XadesSignatureModelContainer dsrm;
                this.firePropertyChange("currentOperation", null, SignatureInfoPanel.this.resource.getString("delete_signature.operation.progress"));
                DeleteSignatureInputModel dsim = new DeleteSignatureInputModel();
                dsim.setSignatureFile(SignatureInfoPanel.this.signatureFile);
                dsim.setDestinationFile(SignatureInfoPanel.this.signatureFile);
                dsim.setSignatureReference(SignatureInfoPanel.this.selectedSignature.getId());
                SignaturesClient sc = new SignaturesClient();
                URI uri2 = sc.deleteSignature(dsim);
                try {
                    dsrm = sc.deleteSignatureResult(uri2);
                }
                catch (ServerException ex) {
                    return new ProgressBarModel(SignatureInfoPanel.this.resource.getString("sign.err_msg.sign_failed") + "\n" + ex.getMessage(), 0);
                }
                if (dsrm != null) {
                    SignatureInfoPanel.this.loadSignatures(dsrm);
                    return new ProgressBarModel(SignatureInfoPanel.this.resource.getString("delete_signature.operation.success"), 1);
                }
                return new ProgressBarModel(SignatureInfoPanel.this.resource.getString("delete_signature.operation.failure"), 1);
            }
        };
        return new ProgressBarDialog(worker);
    }

    private void addVerifyFile(File file) {
        String name = file.getName();
        int k = name.lastIndexOf(".");
        if (k > 0) {
            name = name.substring(k + 1);
        }
        this.signatureFile = file.getPath();
        if ("xades".equals(name)) {
            this.loadXaSignaturesFromFile(this.signatureFile);
            if (!this.isUiInit) {
                this.setLayout(this.layoutXad);
                this.setXadesUi();
                this.isUiInit = true;
            }
        } else if ("pdf".equals(name)) {
            boolean ok;
            if (this.isUiInit) {
                this.setLayout(this.layoutVeri);
                this.setPdfUiInitial();
                this.isUiInit = false;
            }
            if (ok = this.loadPdfSignatures(this.signatureFile)) {
                this.setPdfUi(this.signatureFile);
                if (this.pdfFile != null) {
                    SwingUtilities.invokeLater(() -> SigInfoDialog.show(this.parentWindow, this.pdfFile));
                }
            }
        }
    }

    private void onClickBtnSelectFile(ActionEvent ev) {
        int result;
        String wd;
        UIManager.put("FileChooser.readOnly", Boolean.TRUE);
        JFileChooser jfc = new JFileChooser();
        jfc.setAcceptAllFileFilterUsed(false);
        FileNameExtensionFilter pdfFilter = new FileNameExtensionFilter("PDF file(.pdf)", "pdf");
        FileNameExtensionFilter filterExt = new FileNameExtensionFilter("XAdES signature", "xades");
        jfc.addChoosableFileFilter(pdfFilter);
        jfc.addChoosableFileFilter(filterExt);
        Integer w = AppProp.getInt("verify.JFileChooser.w");
        Integer h = AppProp.getInt("verify.JFileChooser.h");
        if (w != null && h != null) {
            jfc.setPreferredSize(new Dimension(w, h));
        }
        if ((wd = AppProp.getStr("verify.JFileChooser.dir")) != null) {
            jfc.setCurrentDirectory(new File(wd));
        }
        if ((result = jfc.showOpenDialog(this)) == 0) {
            Dimension r = jfc.getSize();
            AppProp.setInt("verify.JFileChooser.w", r.width);
            AppProp.setInt("verify.JFileChooser.h", r.height);
            File dir = jfc.getCurrentDirectory();
            AppProp.setStr("verify.JFileChooser.dir", dir.getPath());
            File file = jfc.getSelectedFile();
            this.addVerifyFile(file);
        }
    }

    private void onMousePressed(MouseEvent evt) {
        int selRow = this.uiSignaturesTree.getRowForLocation(evt.getX(), evt.getY());
        if (selRow != -1 && evt.getClickCount() == 2) {
            this.displayCertificateData(this.selectedSignature.getSigner());
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private void displayCertificateData(CertificateModel certificate) {
        String randomS;
        File tempDerFile;
        Random r = new Random();
        while ((tempDerFile = new File(Single.appTempDir + File.separator + (randomS = Integer.toString(r.nextInt())) + ".der")).exists()) {
        }
        OutputStream fos = null;
        try {
            byte[] encoded = certificate.getCertificate().getEncoded();
            fos = Files.newOutputStream(tempDerFile.toPath(), new OpenOption[0]);
            fos.write(encoded);
        }
        catch (IOException | CertificateEncodingException ex) {
            logger.error("", (Throwable)ex);
        }
        finally {
            try {
                if (fos != null) {
                    fos.close();
                }
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        try {
            Desktop.getDesktop().open(tempDerFile);
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
    }

    private void setupTree() {
        this.uiSignaturesTree.getSelectionModel().setSelectionMode(1);
        this.uiSignaturesTree.setRootVisible(false);
        this.uiSignaturesTree.addTreeSelectionListener(this);
        ImageIcon leafIcon = new ImageIcon(Resource.getImage("/icon_certificate_no_key.png"));
        DefaultTreeCellRenderer renderer = new DefaultTreeCellRenderer();
        renderer.setLeafIcon(leafIcon);
        renderer.setOpenIcon(leafIcon);
        renderer.setClosedIcon(leafIcon);
        this.uiSignaturesTree.setCellRenderer(renderer);
        this.expandTreeNodes();
        this.uiSignaturesTree.setEditable(false);
    }

    private void expandTreeNodes() {
        for (int i = 0; i < this.uiSignaturesTree.getRowCount(); ++i) {
            this.uiSignaturesTree.expandRow(i);
        }
    }

    private void loadXaSignaturesFromFile(String signatureFile) {
        XadesSignatureModelContainer xadesSignatureContainer;
        this.signatureFile = signatureFile;
        GetSignatureFileInputModel gsfim = new GetSignatureFileInputModel();
        gsfim.setSignatureFile(signatureFile);
        SignaturesClient sc = new SignaturesClient();
        URI uri2 = sc.getSignatureInfo(gsfim);
        try {
            xadesSignatureContainer = sc.signatureFileResult(uri2);
        }
        catch (ServerException ex) {
            logger.error("", (Throwable)ex);
            return;
        }
        this.loadSignatures(xadesSignatureContainer);
    }

    private void loadSignatures(XadesSignatureModelContainer xadesSignatureContainer) {
        if (xadesSignatureContainer == null || xadesSignatureContainer.getSignatures() == null || xadesSignatureContainer.getSignatures().isEmpty()) {
            return;
        }
        List<SigningReferenceModel> listRef = this.initFileNames(xadesSignatureContainer.getSignatures());
        this.xadesTableModel.setRefs(listRef);
        this.customSignatureModel = new CustomSignatureModel();
        this.customSignatureModel.setSignatures(xadesSignatureContainer.getSignatures());
        this.uiSignaturesTree.setModel(this.customSignatureModel);
        this.expandTreeNodes();
        this.uiSignaturesTree.repaint();
    }

    @Override
    public void valueChanged(TreeSelectionEvent e) {
        if (!(this.uiSignaturesTree.getLastSelectedPathComponent() instanceof XAdESSignatureModel)) {
            return;
        }
        this.selectedSignature = (XAdESSignatureModel)this.uiSignaturesTree.getLastSelectedPathComponent();
        if (this.selectedSignature.getSigner() == null) {
            return;
        }
        if (this.dcit == null) {
            this.dcit = new DetailsCertInfoTab(this.selectedSignature.getSignatureDetails());
            this.dcit.setVisible(true);
            this.uiPanelSignatureInfo.removeAll();
            this.uiPanelSignatureInfo.add((Component)this.dcit, "Center");
            this.uiPanelSignatureInfo.repaint();
            this.uiPanelSignatureInfo.revalidate();
        } else {
            this.dcit.refreshInfo(this.selectedSignature.getSignatureDetails());
        }
    }

    private List<SigningReferenceModel> initFileNames(List<XAdESSignatureModel> list) {
        ArrayList<SigningReferenceModel> allRefModels = new ArrayList<SigningReferenceModel>();
        ArrayList<String> tmpFileNames = new ArrayList<String>();
        for (XAdESSignatureModel sigModel : list) {
            List<SigningReferenceModel> refModel = sigModel.getReferences();
            for (SigningReferenceModel signingReferenceModel : refModel) {
                String reference = signingReferenceModel.getReference();
                if (tmpFileNames.contains(reference) || reference.startsWith("#")) continue;
                File destination = null;
                try {
                    File f = new File(new URI(reference));
                    destination = new File(new File(this.signatureFile).getParent(), f.getName());
                }
                catch (URISyntaxException ex) {
                    logger.error("", (Throwable)ex);
                }
                tmpFileNames.add(reference);
                if (destination != null && destination.exists()) {
                    signingReferenceModel.setPath(destination.getAbsolutePath());
                }
                allRefModels.add(signingReferenceModel);
            }
        }
        return allRefModels;
    }

    private void setPdfUi(String signaturePath) {
        if (this.pdfFileTableModel.contains(signaturePath)) {
            return;
        }
        this.pdfFileTableModel.add(signaturePath);
    }

    private void setPdfUiInitial() {
        this.uiPanelSignatures.setVisible(false);
        this.uiPanelSignatureInfo.setVisible(false);
        this.btnAddFiles.setVisible(false);
        this.uiPanelSignatureInfo.removeAll();
        this.uiPdfFileTable.setModel(this.pdfFileTableModel);
        this.uiPdfFileTable.addMouseListener(this.pdfFileTableListener);
    }

    private void setXadesUi() {
        this.uiPanelSignatures.setVisible(true);
        this.btnAddFiles.setVisible(true);
        this.buttonRemove.setVisible(false);
        this.pdfFileTableModel.clear();
        this.uiPdfFileTable.removeMouseListener(this.pdfFileTableListener);
        this.uiPdfFileTable.setModel(this.xadesTableModel);
        this.uiPanelSignatureInfo.setVisible(true);
        this.dcit = null;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private boolean loadPdfSignatures(String file) {
        if (this.pdfFile != null) {
            this.pdfFile.close();
            this.pdfFile = null;
        }
        Security.addProvider((Provider)new BouncyCastleProvider());
        try {
            boolean ok;
            this.pdfFile = new PdfFile();
            try {
                ok = this.pdfFile.open(file);
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
                boolean bl = false;
                try {
                    Security.removeProvider("BC");
                }
                catch (SecurityException securityException) {
                    logger.error("", (Throwable)securityException);
                }
                return bl;
            }
            if (!ok) {
                logger.warn("pdfFile not opened");
                boolean bl = false;
                return bl;
            }
            if (!this.pdfFile.hasSignature()) {
                JOptionPane.showMessageDialog(this.uiPanelFileSigned, this.resource.getString("pdfverify.error.nosig"), this.resource.getString("pdfverify.error"), 0);
                logger.warn("The file doesn't contain any signatures");
                boolean bl = false;
                return bl;
            }
            boolean bl = true;
            return bl;
        }
        catch (Exception ex) {
            JOptionPane.showMessageDialog(this.uiPanelFileSigned, this.resource.getString("pdfverify.error.corrupted"), this.resource.getString("pdfverify.error"), 0);
            logger.error("General unknown problem / Corrupted file", (Throwable)ex);
        }
        finally {
            try {
                Security.removeProvider("BC");
            }
            catch (SecurityException securityException) {
                logger.error("", (Throwable)securityException);
            }
        }
        return false;
    }

    @Override
    public void setSelectedFile(String action, String fileName) {
        if (fileName == null) {
            return;
        }
        File file = new File(fileName);
        this.addVerifyFile(file);
    }
}

