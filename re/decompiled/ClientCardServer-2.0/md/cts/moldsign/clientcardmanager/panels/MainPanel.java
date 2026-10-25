/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.panels;

import java.awt.Color;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSeparator;
import javax.swing.JTabbedPane;
import javax.swing.JTextField;
import javax.swing.LayoutStyle;
import md.cts.moldsign.clientcardmanager.panels.TablePanelHolder;
import md.cts.pkcs11.cards.Card;
import md.cts.pkcs11.cards.CardReader;
import md.cts.pkcs11.cards.CardReaderManager;
import md.cts.pkcs11.cards.exceptions.InvalidCardException;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MainPanel
extends JPanel {
    private static final Logger logger = LoggerFactory.getLogger(MainPanel.class);
    private static final Color COLOR_OK_GREEN = new Color(30, 190, 30);
    private static final Color COLOR_FAIL_RED = new Color(190, 30, 30);
    private final Long slotGlobalId;
    public JTextField jtfPinStatus;
    public JTextField jtfPukStatus;
    private JTabbedPane certificateTabs;
    private JTextField jtfFreePrivateMemory;
    private JTextField jtfFreePublicMemory;
    private JTextField jtfTotalPrivateMemory;
    private JTextField jtfTotalPublicMemory;
    private JTextField jtxtCardVersion;
    private JTextField jtxtSerialNumber;

    public MainPanel(Long slotGlobalId) {
        this.slotGlobalId = slotGlobalId;
        this.initComponents();
        TablePanelHolder tph = new TablePanelHolder(slotGlobalId, this);
        tph.refreshTableData();
        this.certificateTabs.add("Profile", tph);
    }

    private void initComponents() {
        this.jtfTotalPrivateMemory = new JTextField();
        JLabel jLabel2 = new JLabel();
        this.jtfFreePublicMemory = new JTextField();
        JLabel jlblSerialNumber = new JLabel();
        this.jtfFreePrivateMemory = new JTextField();
        JSeparator jSeparator1 = new JSeparator();
        JLabel lblTotalPrivateMemory = new JLabel();
        JLabel jLabel1 = new JLabel();
        this.jtxtCardVersion = new JTextField();
        this.jtfTotalPublicMemory = new JTextField();
        JLabel jlblCardVersion = new JLabel();
        JLabel lblFreePrMem = new JLabel();
        this.jtxtSerialNumber = new JTextField();
        this.jtfTotalPrivateMemory.setEditable(false);
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        jLabel2.setText(bundle.getString("cardinfopanel.label.freePublicMemory"));
        this.jtfFreePublicMemory.setEditable(false);
        jlblSerialNumber.setLabelFor(this.jtxtSerialNumber);
        jlblSerialNumber.setText(bundle.getString("cardinfopanel.serial_number"));
        this.jtfFreePrivateMemory.setEditable(false);
        lblTotalPrivateMemory.setText(bundle.getString("cardinfopanel.label.totalPublicMemoru"));
        jLabel1.setText(bundle.getString("cardinfopanel.label.freePrivateMemory"));
        this.jtxtCardVersion.setEditable(false);
        this.jtfTotalPublicMemory.setEditable(false);
        jlblCardVersion.setLabelFor(this.jtxtCardVersion);
        jlblCardVersion.setText(bundle.getString("cardinfopanel.card_version"));
        lblFreePrMem.setText(bundle.getString("cardinfopanel.label.totalPrivateMemory"));
        this.jtxtSerialNumber.setEditable(false);
        JLabel lblPinStatus = new JLabel();
        JLabel lblPukStatus = new JLabel();
        this.jtfPinStatus = new JTextField();
        this.jtfPukStatus = new JTextField();
        lblPinStatus.setText(bundle.getString("cardinfopanel.label.PIN_status"));
        lblPukStatus.setText(bundle.getString("cardinfopanel.label.PUK_status"));
        this.jtfPinStatus.setEditable(false);
        this.jtfPukStatus.setEditable(false);
        JPanel certificatePanelHolder = new JPanel();
        this.certificateTabs = new JTabbedPane();
        GroupLayout certificatePanelHolderLayout = new GroupLayout(certificatePanelHolder);
        certificatePanelHolder.setLayout(certificatePanelHolderLayout);
        certificatePanelHolderLayout.setHorizontalGroup(certificatePanelHolderLayout.createSequentialGroup().addComponent(this.certificateTabs).addContainerGap());
        certificatePanelHolderLayout.setVerticalGroup(certificatePanelHolderLayout.createSequentialGroup().addComponent(this.certificateTabs).addContainerGap());
        JPanel jPanel1 = new JPanel();
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addComponent(jSeparator1).addContainerGap()).addComponent(certificatePanelHolder).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING, false).addComponent(lblPukStatus, GroupLayout.Alignment.LEADING).addComponent(lblPinStatus, GroupLayout.Alignment.LEADING).addComponent(lblTotalPrivateMemory, GroupLayout.Alignment.LEADING).addComponent(lblFreePrMem, GroupLayout.Alignment.LEADING, -1, 130, Short.MAX_VALUE).addComponent(jlblCardVersion, GroupLayout.Alignment.LEADING).addComponent(jlblSerialNumber, GroupLayout.Alignment.LEADING)).addGap(18, 18, 18).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.TRAILING).addComponent(this.jtxtCardVersion).addComponent(this.jtxtSerialNumber, GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING, false).addComponent(this.jtfPinStatus).addComponent(this.jtfPukStatus))).addComponent(this.jtfTotalPrivateMemory, GroupLayout.Alignment.LEADING).addComponent(this.jtfTotalPublicMemory, GroupLayout.Alignment.LEADING)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING, false).addComponent(jLabel1).addComponent(jLabel2)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jtfFreePrivateMemory, -1, 100, Short.MAX_VALUE).addComponent(this.jtfFreePublicMemory)))).addGap(10, 10, 10))));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jlblSerialNumber).addComponent(this.jtxtSerialNumber)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jlblCardVersion).addComponent(this.jtxtCardVersion)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblFreePrMem).addComponent(this.jtfTotalPrivateMemory).addComponent(jLabel1).addComponent(this.jtfFreePrivateMemory)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jtfTotalPublicMemory).addComponent(lblTotalPrivateMemory).addComponent(jLabel2).addComponent(this.jtfFreePublicMemory)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblPinStatus).addComponent(this.jtfPinStatus)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jtfPukStatus).addComponent(lblPukStatus)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jSeparator1, -2, -2, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(certificatePanelHolder));
        JLabel labelImage = new JLabel();
        labelImage.setIcon(new ImageIcon(Resource.getImage((String)"/Potpis 2 resized.jpg")));
        labelImage.setVerticalAlignment(1);
        labelImage.setBorder(BorderFactory.createLineBorder(new Color(164, 164, 164)));
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createSequentialGroup().addContainerGap().addComponent(labelImage).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jPanel1).addContainerGap());
        layout.setVerticalGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup().addComponent(labelImage).addComponent(jPanel1)).addContainerGap());
    }

    public void refreshCardInfo() {
        CardReader slot = CardReaderManager.get().getSlotByGlobalId(this.slotGlobalId);
        if (slot == null) {
            return;
        }
        Card card = slot.getCard();
        if (card == null) {
            return;
        }
        try {
            card.readTokenInfo();
        }
        catch (InvalidCardException ex) {
            logger.error("", (Throwable)ex);
            return;
        }
        this.jtxtSerialNumber.setText(card.getSerialNumber());
        this.jtxtCardVersion.setText(card.getCardVersion());
        try {
            this.jtfTotalPrivateMemory.setText(String.valueOf(card.getTotalPrivateMemory()));
            this.jtfFreePrivateMemory.setText(String.valueOf(card.getFreePrivateMemory()));
            this.jtfTotalPublicMemory.setText(String.valueOf(card.getTotalPublicMemory()));
            this.jtfFreePublicMemory.setText(String.valueOf(card.getFreePublicMemory()));
            if (card.isPinLocked()) {
                this.jtfPinStatus.setForeground(COLOR_FAIL_RED);
                this.jtfPinStatus.setText("Locked");
            } else {
                this.jtfPinStatus.setForeground(COLOR_OK_GREEN);
                this.jtfPinStatus.setText("OK");
            }
            if (card.isPukLocked()) {
                this.jtfPukStatus.setForeground(COLOR_FAIL_RED);
                this.jtfPukStatus.setText("Locked");
            } else {
                this.jtfPukStatus.setForeground(COLOR_OK_GREEN);
                this.jtfPukStatus.setText("OK");
            }
        }
        catch (InvalidCardException ex) {
            logger.error("", (Throwable)ex);
        }
    }
}

