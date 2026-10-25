/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 */
package md.cts.moldsign.clientcardmanager.ui.popups;

import java.awt.Color;
import java.awt.Font;
import java.util.Collection;
import java.util.List;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.KeyStroke;
import javax.swing.LayoutStyle;
import md.cts.moldsign.clientcardmanager.properties.PropertiesLoader;
import md.cts.pkcs11.cards.CardReaderManager;
import md.cts.pkcs11.cards.CardSelector;
import md.ghesar.Resource;

public class DiagnosticDialog
extends JDialog {
    private JTextArea diag;

    public DiagnosticDialog() {
        this.setDefaultCloseOperation(2);
        this.getRootPane().registerKeyboardAction(e -> this.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        this.initComponents();
        this.pack();
    }

    public void fillInformation() {
        this.diag.append("Checking operating system...");
        this.diag.append("\r\n");
        this.diag.append("Operating System: " + System.getProperty("os.name") + ", (" + System.getProperty("os.arch") + ")");
        this.diag.append("\r\n");
        this.diag.append("Java Version: " + System.getProperty("java.version"));
        this.diag.append("\r\n\r\n");
        this.diag.append("driver libs:");
        this.diag.append("\r\n");
        List<String> drivers = PropertiesLoader.readDrivers();
        if (drivers.isEmpty()) {
            this.diag.append("No drivers configured...");
            this.diag.append("\r\n");
        }
        for (String driver : drivers) {
            this.diag.append(driver + "\r\n");
        }
        this.diag.append("\r\n");
        Collection<CardSelector> drvList = CardReaderManager.get().getAllSelector();
        for (CardSelector drv : drvList) {
            this.diag.append(drv.getPkcs11ModuleName());
            this.diag.append("\r\n");
            this.diag.append(drv.getPkcs11ModuleInfo());
            this.diag.append("\r\n\r\n");
        }
    }

    private void initComponents() {
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("diagnosticsdialog.title"));
        this.setIconImage(Resource.getImage((String)"/applogo.png"));
        JLabel imgAboutPage = new JLabel();
        imgAboutPage.setOpaque(true);
        imgAboutPage.setBackground(new Color(15, 24, 56));
        imgAboutPage.setIcon(new ImageIcon(Resource.getImage((String)"/MoldSign 2.jpg")));
        JButton btnClose = new JButton();
        btnClose.setText(bundle.getString("aboutpagepanel.button.close"));
        btnClose.addActionListener(e -> this.dispose());
        JLabel jLabel1 = new JLabel();
        jLabel1.setText(bundle.getString("menu.menu_item.diagnostic"));
        this.diag = new JTextArea();
        this.diag.setEditable(false);
        this.diag.setFont(new Font("Tahoma", 0, 13));
        JScrollPane jScrollPane1 = new JScrollPane();
        jScrollPane1.setViewportView(this.diag);
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(imgAboutPage, -1, -1, Short.MAX_VALUE).addComponent(jLabel1).addComponent(jScrollPane1).addGroup(layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(btnClose))).addContainerGap());
        layout.setVerticalGroup(layout.createSequentialGroup().addContainerGap().addComponent(imgAboutPage).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(jLabel1).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jScrollPane1, -1, 400, Short.MAX_VALUE).addGap(8, 8, 8).addComponent(btnClose).addGap(8, 8, 8).addContainerGap());
    }
}

