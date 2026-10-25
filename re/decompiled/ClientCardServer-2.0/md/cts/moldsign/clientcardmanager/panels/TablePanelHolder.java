/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.gov.stisc.Single
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.panels;

import java.awt.Color;
import java.awt.Desktop;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.LayoutStyle;
import md.cts.moldsign.clientcardmanager.models.CertificateTableModel;
import md.cts.moldsign.clientcardmanager.models.ImageRenderer;
import md.cts.moldsign.clientcardmanager.panels.MainPanel;
import md.cts.moldsign.clientcardmanager.ui.popups.ChangePinDialog;
import md.cts.moldsign.clientcardmanager.ui.popups.ChangePinViaPukDialog;
import md.cts.pkcs11.cards.Card;
import md.cts.pkcs11.cards.CardReader;
import md.cts.pkcs11.cards.CardReaderManager;
import md.cts.pkcs11.cards.certificates.CardObjectManipulation;
import md.cts.pkcs11.cards.certificates.CertificateFull;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.gov.stisc.Single;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TablePanelHolder
extends JPanel {
    private static final Logger logger = LoggerFactory.getLogger(TablePanelHolder.class);
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    private final TablePanelHolder tph;
    private final MainPanel mpanel;
    private final Long slotGlobalId;
    private CertificateTableModel certModel = null;
    private JTable tblCertificateTable;

    public TablePanelHolder(Long slotGlobalId, MainPanel pnl) {
        this.slotGlobalId = slotGlobalId;
        List<CertificateFull> listCerts = this.getCertificatesWithPresentPrivateKeys();
        this.certModel = new CertificateTableModel(listCerts);
        this.tph = this;
        this.initComponents();
        this.tblCertificateTable.getColumnModel().getColumn(0).setCellRenderer(new ImageRenderer());
        this.tblCertificateTable.getColumnModel().getColumn(0).setMaxWidth(40);
        this.mpanel = pnl;
        this.tblCertificateTable.addMouseListener(new MouseAdapter(){

            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    TablePanelHolder.this.tph.displayCertificateData();
                }
            }
        });
    }

    private List<CertificateFull> getCertificatesWithPresentPrivateKeys() {
        ArrayList<CertificateFull> tmpCertificates = new ArrayList<CertificateFull>();
        CardReader slot = CardReaderManager.get().getSlotByGlobalId(this.slotGlobalId);
        if (slot == null) {
            return tmpCertificates;
        }
        List<CertificateFull> allCertificates = CardObjectManipulation.getInstance(this.slotGlobalId).getPKCS11Certificates();
        for (CertificateFull certificateFull : allCertificates) {
            if (!certificateFull.isPrivateKeyPresent() || !certificateFull.hasCert()) continue;
            tmpCertificates.add(certificateFull);
        }
        return tmpCertificates;
    }

    public void displayCertificateData() {
        int selectedRow = this.tblCertificateTable.getSelectedRow();
        if (selectedRow != -1) {
            String randomS;
            File tempDerFile;
            CertificateFull cf = this.certModel.getCertificateAt(selectedRow);
            Random r = new Random();
            while ((tempDerFile = new File(Single.appTempDir + File.separator + "_" + (randomS = Integer.toString(r.nextInt())) + ".der")).exists()) {
            }
            boolean ok = cf.save(tempDerFile.getPath());
            if (ok) {
                try {
                    Desktop.getDesktop().open(tempDerFile);
                }
                catch (IOException ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        } else if (this.tblCertificateTable.getRowCount() == 0) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("generalprofile.error_msg.no_certificates"), this.rbundle.getString("generalprofile.error_msg.no_certificates"), 0);
        } else {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("generalprofile.error_msg.select_certificate"), this.rbundle.getString("generalprofile.error_msg.select_certificate"), 0);
        }
    }

    public void refreshTableData() {
        try {
            CardObjectManipulation.getInstance(this.slotGlobalId).refreshCertificates();
            List<CertificateFull> list = this.cleanCertificateList();
            this.certModel.setCerts(list);
        }
        catch (OperationFailedException ex) {
            logger.error("", (Throwable)ex);
        }
    }

    private List<CertificateFull> cleanCertificateList() {
        ArrayList<CertificateFull> cleanList = new ArrayList<CertificateFull>();
        List<CertificateFull> cert = CardObjectManipulation.getInstance(this.slotGlobalId).getPKCS11Certificates();
        for (CertificateFull tokCert : cert) {
            if (tokCert.hasCert()) {
                cleanList.add(tokCert);
                continue;
            }
            logger.info("X509 not found");
        }
        return cleanList;
    }

    private void initComponents() {
        JButton btnDisplayCertificate = new JButton();
        JButton jbtnChangePin = new JButton();
        JButton lbtnNewPin = new JButton();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        btnDisplayCertificate.setText(bundle.getString("secureprofilepanel.display_certificate_data"));
        btnDisplayCertificate.addActionListener(this::btnDisplayCertificateActionPerformed);
        jbtnChangePin.setText(bundle.getString("cardinfopanel.change_pin"));
        jbtnChangePin.addActionListener(this::jbtnChangePinActionPerformed);
        lbtnNewPin.setText(bundle.getString("cardinfopanel.new_pin"));
        lbtnNewPin.addActionListener(this::lbtnNewPinActionPerformed);
        this.tblCertificateTable = new JTable();
        this.tblCertificateTable.setAutoCreateRowSorter(true);
        this.tblCertificateTable.setModel(this.certModel);
        this.tblCertificateTable.setGridColor(new Color(49, 106, 197));
        this.tblCertificateTable.setRowHeight(27);
        this.tblCertificateTable.setShowHorizontalLines(false);
        this.tblCertificateTable.setShowVerticalLines(false);
        this.tblCertificateTable.getTableHeader().setReorderingAllowed(false);
        JScrollPane jScrollPane1 = new JScrollPane();
        jScrollPane1.setPreferredSize(new Dimension(220, 210));
        jScrollPane1.setViewportView(this.tblCertificateTable);
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addGroup(layout.createParallelGroup(GroupLayout.Alignment.TRAILING).addComponent(jScrollPane1).addGroup(layout.createSequentialGroup().addComponent(btnDisplayCertificate, -2, 150, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(lbtnNewPin, -2, 150, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jbtnChangePin, -2, 150, -2)))));
        layout.setVerticalGroup(layout.createSequentialGroup().addComponent(jScrollPane1, -1, -2, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(layout.createParallelGroup().addComponent(btnDisplayCertificate).addComponent(jbtnChangePin).addComponent(lbtnNewPin)));
    }

    private void btnDisplayCertificateActionPerformed(ActionEvent evt) {
        this.tph.displayCertificateData();
    }

    private void jbtnChangePinActionPerformed(ActionEvent evt) {
        CardReader slot = CardReaderManager.get().getSlotByGlobalId(this.slotGlobalId);
        if (slot == null) {
            return;
        }
        Card card = slot.getCard();
        if (card == null) {
            return;
        }
        ChangePinDialog cpi = new ChangePinDialog(null, true);
        cpi.setCrdName(slot.getName());
        cpi.initiateCustomStringForFS();
        cpi.refreshCardInfo(card);
        cpi.setLocationRelativeTo(this);
        cpi.setVisible(true);
    }

    private void lbtnNewPinActionPerformed(ActionEvent evt) {
        CardReader slot = CardReaderManager.get().getSlotByGlobalId(this.slotGlobalId);
        if (slot == null) {
            return;
        }
        Card card = slot.getCard();
        if (card == null) {
            return;
        }
        ChangePinViaPukDialog cpvp = new ChangePinViaPukDialog(null, true, this.mpanel);
        cpvp.setCrdName(slot.getName());
        cpvp.initiateCustomStringForFS();
        cpvp.refreshCardInfo(card);
        cpvp.setLocationRelativeTo(this);
        cpvp.setVisible(true);
    }
}

