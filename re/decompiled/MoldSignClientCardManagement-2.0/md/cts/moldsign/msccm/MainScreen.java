/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm;

import java.awt.Color;
import java.awt.Component;
import java.awt.Insets;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import javax.swing.LayoutStyle;
import javax.swing.UIManager;
import javax.swing.event.ChangeEvent;
import md.cts.moldsign.msccm.TabPanel;
import md.cts.moldsign.msccm.panels.SignMultipleFilesPanel;
import md.cts.moldsign.msccm.panels.SignatureInfoPanel;
import md.cts.moldsign.msccm.panels.tabs.EncryptionDecryptionPanel;
import md.cts.moldsign.msccm.panels.tabs.SafeDeletePanel;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class MainScreen
extends JFrame {
    private static final Logger logger = LoggerFactory.getLogger(MainScreen.class);
    private static final Integer SIGN_TAB = 0;
    private static final Integer VERIFY_TAB = 1;
    private static final Integer ENCRYPT_DECRYPT_TAB = 2;
    private static final Integer SAFE_DELETE_TAB = 3;
    private final ResourceBundle resource = ResourceBundle.getBundle("translations");
    private final Map<Integer, TabPanel> panels = new HashMap<Integer, TabPanel>(4);
    private JTabbedPane tabMenu;

    public MainScreen() {
        this.setDefaultCloseOperation(3);
        this.setUI();
        this.initComponents();
        this.initTabs();
    }

    public MainScreen(String[] args) {
        this();
        if (args.length > 0) {
            String operation = args[0];
            String fileName = args[1];
            operation = operation.trim().toLowerCase();
            TabPanel selectedPanel = null;
            if ("-sign".equals(operation)) {
                selectedPanel = this.panels.get(SIGN_TAB);
                if (fileName.toLowerCase().contains("moldsign://".toLowerCase())) {
                    fileName = fileName.replace("moldsign://", "");
                    fileName = fileName.substring(0, fileName.length() - 1);
                }
            }
            if ("-verify".equals(operation)) {
                selectedPanel = this.panels.get(VERIFY_TAB);
            }
            if ("-encr_pass".equals(operation)) {
                selectedPanel = this.panels.get(ENCRYPT_DECRYPT_TAB);
            }
            if ("-decr_pass".equals(operation)) {
                selectedPanel = this.panels.get(ENCRYPT_DECRYPT_TAB);
            }
            if ("-encr_cert".equals(operation)) {
                selectedPanel = this.panels.get(ENCRYPT_DECRYPT_TAB);
            }
            if ("-decr_cert".equals(operation)) {
                selectedPanel = this.panels.get(ENCRYPT_DECRYPT_TAB);
            }
            if ("-delete".equals(operation)) {
                selectedPanel = this.panels.get(SAFE_DELETE_TAB);
            }
            if (selectedPanel != null) {
                selectedPanel.setSelectedFile(operation, fileName);
                this.tabMenu.setSelectedComponent((Component)((Object)selectedPanel));
            }
        }
    }

    private void initComponents() {
        JLabel jLabel1 = new JLabel();
        jLabel1.setOpaque(true);
        jLabel1.setBackground(new Color(15, 24, 56));
        URL url = MainScreen.class.getResource("/MoldSign 2.jpg");
        if (url != null) {
            jLabel1.setIcon(new ImageIcon(url));
        }
        JPanel jPanel1 = new JPanel();
        this.tabMenu = new JTabbedPane();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("application.name") + " 2.4.12");
        this.setIconImage(Resource.getImage("/applogo.png"));
        this.tabMenu.addChangeListener(this::tabMenuStateChanged);
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jLabel1, 0, -1, Short.MAX_VALUE).addComponent(this.tabMenu, -2, -2, Short.MAX_VALUE));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createSequentialGroup().addComponent(jLabel1).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.tabMenu, -1, -1, Short.MAX_VALUE));
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createSequentialGroup().addComponent(jPanel1, 0, 1000, Short.MAX_VALUE));
        layout.setVerticalGroup(layout.createSequentialGroup().addComponent(jPanel1, 0, 550, Short.MAX_VALUE));
        this.pack();
    }

    private void tabMenuStateChanged(ChangeEvent evt) {
        this.tabMenu.getSelectedIndex();
    }

    private void initTabs() {
        this.panels.put(SIGN_TAB, new SignMultipleFilesPanel());
        this.panels.put(VERIFY_TAB, new SignatureInfoPanel(this));
        this.panels.put(ENCRYPT_DECRYPT_TAB, new EncryptionDecryptionPanel());
        this.panels.put(SAFE_DELETE_TAB, new SafeDeletePanel());
        ImageIcon sign = new ImageIcon(Resource.getImage("/icon_sign.png"));
        ImageIcon verify = new ImageIcon(Resource.getImage("/icon_verify.png"));
        ImageIcon encrypt = new ImageIcon(Resource.getImage("/icon_encrypt.png"));
        ImageIcon delete = new ImageIcon(Resource.getImage("/icon_trash.png"));
        this.tabMenu.addTab(this.resource.getString("sign.btn.sign"), sign, (Component)((Object)this.panels.get(SIGN_TAB)));
        this.tabMenu.addTab(this.resource.getString("verify.btn.verify"), verify, (Component)((Object)this.panels.get(VERIFY_TAB)));
        this.tabMenu.addTab(this.resource.getString("btn.encrypt_decrypt"), encrypt, (Component)((Object)this.panels.get(ENCRYPT_DECRYPT_TAB)));
        this.tabMenu.addTab(this.resource.getString("btn.safe_delete"), delete, (Component)((Object)this.panels.get(SAFE_DELETE_TAB)));
        this.tabMenu.setBorder(null);
        this.tabMenu.putClientProperty("TabbedPane.textIconGap", 10);
    }

    private void setUI() {
        UIManager.put("TabbedPane.tabInsets", new Insets(5, 5, 5, 5));
        UIManager.put("TabbedPane.textIconGap", 10);
    }
}

