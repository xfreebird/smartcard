/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.clientcardmanager.ui.configuration.popups;

import java.awt.event.ActionEvent;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.JCheckBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSeparator;
import javax.swing.JTextField;
import javax.swing.LayoutStyle;
import md.cts.moldsign.clientcardmanager.properties.PropertiesLoader;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.ConfigurationSaveInterface;

public class ProxyConfigurationPanel
extends JPanel
implements ConfigurationSaveInterface {
    private JCheckBox cbxUseProxy;
    private JTextField txtProxyHost;
    private JTextField txtProxyPort;

    public ProxyConfigurationPanel() {
        String proxyUse = PropertiesLoader.getProperties("PKCS11").getProperty("http_proxy_use");
        String proxyHost = PropertiesLoader.getProperties("PKCS11").getProperty("http_proxy_url");
        String proxyPort = PropertiesLoader.getProperties("PKCS11").getProperty("http_proxy_port");
        this.initComponents();
        this.txtProxyHost.setText(proxyHost);
        this.txtProxyPort.setText(proxyPort);
        this.cbxUseProxy.setSelected("true".equals(proxyUse));
        this.setActiveStatus();
    }

    private void setActiveStatus() {
        if (this.cbxUseProxy.isSelected()) {
            this.txtProxyHost.setEnabled(true);
            this.txtProxyPort.setEnabled(true);
        } else {
            this.txtProxyHost.setEnabled(false);
            this.txtProxyPort.setEnabled(false);
        }
    }

    private void initComponents() {
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        JPanel jPanel1 = new JPanel();
        this.cbxUseProxy = new JCheckBox();
        JSeparator jSeparator1 = new JSeparator();
        JLabel jLabel1 = new JLabel();
        JLabel jLabel2 = new JLabel();
        this.txtProxyHost = new JTextField();
        this.txtProxyPort = new JTextField();
        jPanel1.setBorder(BorderFactory.createTitledBorder(bundle.getString("propertiesconfiguration.label.proxy_configuration")));
        this.cbxUseProxy.setText(bundle.getString("propertiesconfiguration.label.proxy_use"));
        this.cbxUseProxy.addActionListener(this::cbxUseProxyActionPerformed);
        jLabel1.setLabelFor(this.txtProxyHost);
        jLabel1.setText(bundle.getString("propertiesconfiguration.label.proxy_host"));
        jLabel2.setLabelFor(this.txtProxyPort);
        jLabel2.setText(bundle.getString("propertiesconfiguration.label.proxy_port"));
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup().addComponent(this.cbxUseProxy).addComponent(jSeparator1).addGroup(jPanel1Layout.createSequentialGroup().addGroup(jPanel1Layout.createParallelGroup().addComponent(jLabel1).addComponent(jLabel2)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup().addComponent(this.txtProxyHost).addComponent(this.txtProxyPort)))).addContainerGap());
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addComponent(this.cbxUseProxy).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(jSeparator1, -2, 10, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel1).addComponent(this.txtProxyHost, -2, -1, -2)).addGap(9, 9, 9).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel2).addComponent(this.txtProxyPort, -2, -1, -2)).addContainerGap(82, Short.MAX_VALUE));
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -2, Short.MAX_VALUE).addContainerGap());
        layout.setVerticalGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -2, Short.MAX_VALUE).addContainerGap());
    }

    private void cbxUseProxyActionPerformed(ActionEvent evt) {
        this.setActiveStatus();
    }

    @Override
    public void onSaveConfiguration() {
        PropertiesLoader.setProperty("PKCS11", "http_proxy_use", String.valueOf(this.cbxUseProxy.isSelected()));
        PropertiesLoader.setProperty("PKCS11", "http_proxy_url", this.txtProxyHost.getText());
        PropertiesLoader.setProperty("PKCS11", "http_proxy_port", this.txtProxyPort.getText());
        PropertiesLoader.setupHttpProxy();
    }
}

