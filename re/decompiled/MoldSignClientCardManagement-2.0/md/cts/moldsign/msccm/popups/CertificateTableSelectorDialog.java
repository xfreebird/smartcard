/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.popups;

import java.awt.Color;
import java.awt.Frame;
import java.awt.event.ActionEvent;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.KeyStroke;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import javax.swing.table.DefaultTableModel;
import md.cts.moldsign.msccm.models.CustomCertificatePopupTableModel;
import md.cts.moldsign.msccm.models.ImageRenderer;
import md.cts.moldsign.msccm.models.ProgressBarModel;
import md.cts.moldsign.msccm.observers.SelectCertificateObserver;
import md.cts.moldsign.msccm.popups.ProgressBarDialog;
import md.cts.moldsign.msccm.rest.clients.CertificatesClient;
import md.cts.moldsign.msccm.subjects.SelectCertificateSubject;
import md.cts.moldsign.transferobjects.models.CertificateListModel;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.ghesar.Resource;

public class CertificateTableSelectorDialog
extends JDialog
implements SelectCertificateSubject {
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    private final boolean allCertificates;
    private final ArrayList<SelectCertificateObserver> listObservers = new ArrayList();
    private CustomCertificatePopupTableModel tableModel;
    private JButton btnImportCertificate;
    private JTable certificateTable;

    public CertificateTableSelectorDialog(Frame parent, boolean modal, boolean all) {
        super(parent, modal);
        this.setDefaultCloseOperation(2);
        this.getRootPane().registerKeyboardAction(e -> this.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        this.allCertificates = all;
        this.initComponents();
        this.btnImportCertificate.setVisible(all);
        this.initCertificates();
    }

    public CertificateTableSelectorDialog(Frame parent, boolean modal) {
        this(parent, modal, false);
    }

    private void initComponents() {
        JPanel jPanel1 = new JPanel();
        JScrollPane jScrollPane1 = new JScrollPane();
        this.certificateTable = new JTable();
        JButton btnOk = new JButton();
        JButton btnCacel = new JButton();
        JButton btnRefresh = new JButton();
        this.btnImportCertificate = new JButton();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("title.certificate_selector"));
        this.setIconImage(Resource.getImage("/applogo.png"));
        jPanel1.setBorder(BorderFactory.createTitledBorder(null, bundle.getString("title.border.selectcertificate"), 0, 0, null, new Color(0, 0, 0)));
        this.certificateTable.setModel(new DefaultTableModel(new Object[][]{{null, null, null, null}, {null, null, null, null}, {null, null, null, null}, {null, null, null, null}}, new String[]{"Title 1", "Title 2", "Title 3", "Title 4"}));
        this.certificateTable.setFillsViewportHeight(true);
        this.certificateTable.setGridColor(new Color(255, 255, 255));
        this.certificateTable.setRowHeight(27);
        jScrollPane1.setViewportView(this.certificateTable);
        btnOk.setText(bundle.getString("btn.ok"));
        btnOk.addActionListener(this::btnOkActionPerformed);
        btnCacel.setText(bundle.getString("btn.cancel"));
        btnCacel.addActionListener(this::btnCacelActionPerformed);
        btnRefresh.setText(bundle.getString("btn.refresh"));
        btnRefresh.addActionListener(this::btnRefreshActionPerformed);
        this.btnImportCertificate.setText(bundle.getString("btn.import_certificate"));
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jScrollPane1, -1, 800, Short.MAX_VALUE).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addComponent(btnRefresh).addGap(18, 18, 18).addComponent(this.btnImportCertificate).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, -1, Short.MAX_VALUE).addComponent(btnOk).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(btnCacel))).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addComponent(jScrollPane1, -1, 202, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnCacel).addComponent(btnOk).addComponent(btnRefresh).addComponent(this.btnImportCertificate)).addContainerGap()));
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        this.pack();
    }

    private void btnCacelActionPerformed(ActionEvent evt) {
        this.dispose();
    }

    private void btnOkActionPerformed(ActionEvent evt) {
        int selectedRow = this.certificateTable.getSelectedRow();
        if (selectedRow != -1) {
            this.notifyObservers();
            this.dispose();
        } else {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("nocertificateselected"), this.rbundle.getString("nocertificateselected"), 0);
        }
    }

    private void btnRefreshActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, CertificateTableSelectorDialog.this.rbundle.getString("certificates.refreshing"));
                CertificatesClient cc = new CertificatesClient();
                cc.refreshCertificates();
                CertificateTableSelectorDialog.this.initCertificates();
                return null;
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    private void initCertificates() {
        this.certificateTable.removeAll();
        CertificatesClient cc = new CertificatesClient();
        CertificateListModel cm = this.allCertificates ? cc.getListOfCertificatesAll() : cc.getListOfCertificatesPrivateOnly();
        ArrayList<CertificateModel> cml = new ArrayList<CertificateModel>(cm.getCertificateModel());
        this.tableModel = new CustomCertificatePopupTableModel(cml);
        this.certificateTable.setModel(this.tableModel);
        this.certificateTable.getColumnModel().getColumn(0).setCellRenderer(new ImageRenderer());
        this.certificateTable.getColumnModel().getColumn(0).setMaxWidth(40);
        this.certificateTable.addMouseListener(new MouseAdapter(){

            @Override
            public void mouseClicked(MouseEvent e) {
                int selectedRow;
                if (e.getClickCount() == 2 && (selectedRow = CertificateTableSelectorDialog.this.certificateTable.getSelectedRow()) != -1) {
                    CertificateTableSelectorDialog.this.notifyObservers();
                    CertificateTableSelectorDialog.this.dispose();
                }
            }
        });
    }

    @Override
    public void registerObserver(SelectCertificateObserver o) {
        this.listObservers.add(o);
    }

    @Override
    public void removeObserver(SelectCertificateObserver o) {
        this.listObservers.remove(o);
    }

    @Override
    public void notifyObservers() {
        for (SelectCertificateObserver selectCertificateObserver : this.listObservers) {
            selectCertificateObserver.onCertificateSelected(this.tableModel.getCertificateAt(this.certificateTable.getSelectedRow()));
        }
    }
}

