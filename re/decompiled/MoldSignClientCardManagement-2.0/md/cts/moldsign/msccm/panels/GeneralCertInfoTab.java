/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.panels;

import java.awt.Color;
import java.awt.Font;
import java.text.DateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSeparator;
import javax.swing.LayoutStyle;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.ghesar.Resource;

public final class GeneralCertInfoTab
extends JPanel {
    private final CertificateModel cert;
    private JLabel jLabel1;
    private JLabel jLabel11;
    private JLabel jLabel13;
    private JLabel jLabel15;
    private JLabel jLabel2;
    private JLabel jLabel3;
    private JLabel jLabel4;
    private JLabel jLabel7;
    private JLabel jLabel8;
    private JPanel jPanel1;
    private JScrollPane jScrollPane1;
    private JSeparator jSeparator1;
    private JSeparator jSeparator2;
    private JSeparator jSeparator3;
    private JLabel lblIssuedBy;
    private JLabel lblIssuedTo;
    private JLabel lblValidFrom;
    private JLabel lblValidTo;
    private JLabel policy;
    private JLabel validToday;

    public GeneralCertInfoTab(CertificateModel cert) {
        this.initComponents();
        this.cert = cert;
        this.initFields();
    }

    private void initComponents() {
        this.jScrollPane1 = new JScrollPane();
        this.jPanel1 = new JPanel();
        this.jLabel13 = new JLabel();
        this.jLabel1 = new JLabel();
        this.jLabel7 = new JLabel();
        this.lblValidTo = new JLabel();
        this.lblValidFrom = new JLabel();
        this.jSeparator1 = new JSeparator();
        this.jLabel8 = new JLabel();
        this.jLabel2 = new JLabel();
        this.jLabel11 = new JLabel();
        this.jSeparator2 = new JSeparator();
        this.policy = new JLabel();
        this.jLabel3 = new JLabel();
        this.lblIssuedTo = new JLabel();
        this.lblIssuedBy = new JLabel();
        this.jSeparator3 = new JSeparator();
        this.jLabel15 = new JLabel();
        this.validToday = new JLabel();
        this.jLabel4 = new JLabel();
        this.setBorder(BorderFactory.createEtchedBorder());
        this.jPanel1.setBackground(new Color(255, 255, 255));
        this.jLabel13.setFont(new Font("Tahoma", 1, 11));
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.jLabel13.setText(bundle.getString("certinfo.lbl.to"));
        this.jLabel1.setIcon(new ImageIcon(Resource.getImage("/icon_certificate_no_key.png")));
        this.jLabel7.setFont(new Font("Tahoma", 1, 11));
        this.jLabel7.setText(bundle.getString("certinfo.lbl.issuedTo"));
        this.lblValidTo.setText("01/05/2014");
        this.lblValidFrom.setText("01/05/2012");
        this.jLabel8.setFont(new Font("Tahoma", 1, 11));
        this.jLabel8.setText(bundle.getString("certinfo.lbl.issuedBy"));
        this.jLabel2.setFont(new Font("Tahoma", 1, 12));
        this.jLabel2.setText(bundle.getString("certinfo.lbl.CertificateInformation"));
        this.jLabel11.setFont(new Font("Tahoma", 1, 11));
        this.jLabel11.setText(bundle.getString("certinfo.lbl.validFrom"));
        this.policy.setText("- 1.2.112.223.34");
        this.jLabel3.setFont(new Font("Tahoma", 1, 11));
        this.jLabel3.setText(bundle.getString("certinfo.lbl.ThisCertificateIsIntended"));
        this.lblIssuedTo.setText("Pantaz George");
        this.lblIssuedBy.setText("MoldSign");
        this.jLabel15.setFont(new Font("Tahoma", 1, 11));
        this.jLabel15.setText(bundle.getString("validToday"));
        this.validToday.setText("jLabel9");
        this.jLabel4.setFont(new Font("Tahoma", 1, 11));
        this.jLabel4.setText(bundle.getString("policy"));
        GroupLayout jPanel1Layout = new GroupLayout(this.jPanel1);
        this.jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jSeparator1).addComponent(this.jSeparator2).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addComponent(this.jLabel1).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.jLabel2)).addComponent(this.jLabel3).addGroup(jPanel1Layout.createSequentialGroup().addGap(22, 22, 22).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addComponent(this.jLabel8).addGap(18, 18, 18).addComponent(this.lblIssuedBy)).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.TRAILING, false).addGroup(GroupLayout.Alignment.LEADING, jPanel1Layout.createSequentialGroup().addComponent(this.jLabel7).addGap(18, 18, 18).addComponent(this.lblIssuedTo, -1, -1, Short.MAX_VALUE)).addGroup(GroupLayout.Alignment.LEADING, jPanel1Layout.createSequentialGroup().addComponent(this.jLabel11).addGap(18, 18, 18).addComponent(this.lblValidFrom).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.jLabel13))).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.lblValidTo))))).addGap(0, 81, Short.MAX_VALUE)).addComponent(this.jSeparator3))).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addGap(35, 35, 35).addComponent(this.jLabel15).addGap(36, 36, 36).addComponent(this.validToday)).addGroup(jPanel1Layout.createSequentialGroup().addGap(40, 40, 40).addComponent(this.jLabel4).addGap(18, 18, 18).addComponent(this.policy))).addGap(0, 0, Short.MAX_VALUE))).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.TRAILING).addComponent(this.jLabel2).addComponent(this.jLabel1)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.jSeparator1, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.jLabel3).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.policy).addComponent(this.jLabel4)).addGap(109, 109, 109).addComponent(this.jSeparator2, -2, 10, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jLabel7).addComponent(this.lblIssuedTo)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jLabel8).addComponent(this.lblIssuedBy)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jLabel11).addComponent(this.lblValidFrom).addComponent(this.jLabel13).addComponent(this.lblValidTo)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.jSeparator3, -2, 10, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jLabel15).addComponent(this.validToday)).addContainerGap(72, Short.MAX_VALUE)));
        this.jScrollPane1.setViewportView(this.jPanel1);
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(this.jScrollPane1, -2, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(this.jScrollPane1, -1, 387, Short.MAX_VALUE).addContainerGap()));
    }

    private void initFields() {
        this.lblIssuedBy.setText(this.cert.getSubjectDN());
        this.lblIssuedBy.setText(this.cert.getIssuerDN());
        this.lblValidFrom.setText(this.formatDate(this.cert.getCertificate().getNotBefore()));
        this.lblValidTo.setText(this.formatDate(this.cert.getCertificate().getNotAfter()));
        this.policy.setText(this.cert.getPolicyOid());
    }

    private String formatDate(Date d) {
        DateFormat df = DateFormat.getDateTimeInstance(2, 2, Locale.getDefault());
        return df.format(d);
    }
}

