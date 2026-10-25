/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 */
package md.cts.moldsign.clientcardmanager.ui.configuration.popups;

import java.awt.Color;
import java.awt.Component;
import java.awt.event.ActionEvent;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JTabbedPane;
import javax.swing.KeyStroke;
import javax.swing.LayoutStyle;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.ConfigurationSaveInterface;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.DriversConfigurationPanel;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.LanguageConfigurationPanel;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.ProxyConfigurationPanel;
import md.ghesar.Resource;

public class ConfigurationDialogMain
extends JDialog {
    private final ResourceBundle resource = ResourceBundle.getBundle("translations");
    private JTabbedPane configurationTabs;

    public ConfigurationDialogMain() {
        this.setDefaultCloseOperation(2);
        this.getRootPane().registerKeyboardAction(e -> this.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        this.initComponents();
        this.pack();
    }

    private void initComponents() {
        JLabel jLabel1 = new JLabel();
        jLabel1.setOpaque(true);
        jLabel1.setBackground(new Color(15, 24, 56));
        jLabel1.setIcon(new ImageIcon(Resource.getImage((String)"/MoldSign 2.jpg")));
        this.configurationTabs = new JTabbedPane();
        JButton jButton1 = new JButton();
        JButton jButton2 = new JButton();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("configurationdialog.title"));
        this.setIconImage(Resource.getImage((String)"/applogo.png"));
        jButton1.setText(bundle.getString("button.close"));
        jButton1.addActionListener(e -> this.dispose());
        jButton2.setText(bundle.getString("button.ok"));
        jButton2.addActionListener(this::jButton2ActionPerformed);
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jLabel1, -1, -1, Short.MAX_VALUE).addComponent(this.configurationTabs).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(jButton2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(jButton1))).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jLabel1, -2, 34, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.configurationTabs, -1, 360, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jButton1).addComponent(jButton2)).addContainerGap()));
    }

    private void jButton2ActionPerformed(ActionEvent evt) {
        Component[] components;
        for (Component c : components = this.configurationTabs.getComponents()) {
            if (!(c instanceof ConfigurationSaveInterface)) continue;
            ConfigurationSaveInterface ci = (ConfigurationSaveInterface)((Object)c);
            ci.onSaveConfiguration();
        }
        this.dispose();
    }

    public void initTabs() {
        DriversConfigurationPanel dcp = new DriversConfigurationPanel();
        LanguageConfigurationPanel lcp = new LanguageConfigurationPanel();
        ProxyConfigurationPanel pcp = new ProxyConfigurationPanel();
        this.configurationTabs.add(this.resource.getString("configurationtab.settings"), dcp);
        this.configurationTabs.add(this.resource.getString("configurationtab.language"), lcp);
        this.configurationTabs.add(this.resource.getString("configurationtab.proxy"), pcp);
        this.pack();
    }
}

