/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.panels;

import java.awt.Color;
import java.awt.Font;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;
import javax.swing.GroupLayout;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextArea;
import md.cts.moldsign.msccm.models.CertificateTableModel;
import md.cts.moldsign.transferobjects.models.CertificateDetailsModel;

public class DetailsCertInfoTab
extends JPanel {
    private final CertificateTableModel certModel;
    private JTable certDetailsTable;
    private JScrollPane jScrollPane1;
    private JScrollPane jScrollPane3;
    private JTextArea moreInfo;

    public DetailsCertInfoTab(List<CertificateDetailsModel> certDetailsModel) {
        this.certModel = new CertificateTableModel(certDetailsModel);
        this.initComponents();
        this.certDetailsTable.addMouseListener(new MouseAdapter(){

            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 1) {
                    CertificateDetailsModel cdm = DetailsCertInfoTab.this.certModel.getCertificateAt(DetailsCertInfoTab.this.certDetailsTable.getSelectedRow());
                    DetailsCertInfoTab.this.moreInfo.setText(cdm.getDescription());
                }
            }
        });
    }

    public void refreshInfo(List<CertificateDetailsModel> certDetailsModel) {
        this.certModel.setCerts(certDetailsModel);
        this.moreInfo.setText("");
    }

    private void initComponents() {
        this.jScrollPane1 = new JScrollPane();
        this.certDetailsTable = new JTable();
        this.jScrollPane3 = new JScrollPane();
        this.moreInfo = new JTextArea();
        this.certDetailsTable.setModel(this.certModel);
        this.certDetailsTable.setFillsViewportHeight(true);
        this.certDetailsTable.setGridColor(new Color(255, 255, 255));
        this.jScrollPane1.setViewportView(this.certDetailsTable);
        this.moreInfo.setEditable(false);
        this.moreInfo.setColumns(20);
        this.moreInfo.setFont(new Font("Tahoma", 0, 13));
        this.moreInfo.setRows(5);
        this.jScrollPane3.setViewportView(this.moreInfo);
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jScrollPane1, -1, 380, Short.MAX_VALUE).addComponent(this.jScrollPane3, GroupLayout.Alignment.TRAILING, -2, -1, Short.MAX_VALUE)).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(this.jScrollPane1, -1, 143, Short.MAX_VALUE).addGap(18, 18, 18).addComponent(this.jScrollPane3, -1, 115, Short.MAX_VALUE).addContainerGap()));
    }
}

