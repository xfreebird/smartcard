/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.gov.stisc.Single
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.ui.configuration.popups;

import java.awt.event.ActionEvent;
import java.io.File;
import java.util.List;
import java.util.ResourceBundle;
import java.util.Vector;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import javax.swing.filechooser.FileNameExtensionFilter;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.cryptography.providers.MSCSPSecurityProvider;
import md.cts.cryptography.providers.SecurityOperationsProviderManager;
import md.cts.moldsign.clientcardmanager.models.ProgressBarModel;
import md.cts.moldsign.clientcardmanager.properties.PropertiesLoader;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.ConfigurationSaveInterface;
import md.cts.moldsign.clientcardmanager.ui.popups.ProgressBarDialog;
import md.cts.pkcs11.cards.CardReaderManager;
import md.gov.stisc.Single;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DriversConfigurationPanel
extends JPanel
implements ConfigurationSaveInterface {
    private static final Logger logger = LoggerFactory.getLogger(DriversConfigurationPanel.class);
    private static boolean usePdfPreview = true;
    private static boolean signatureAppearance = true;
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    private final Vector<String> vecDrivers;
    private JCheckBox MscspOnCheckB;
    private JCheckBox checkBoxPdfPreview;
    private JCheckBox checkBoxAppearance;
    private JList<String> jlDriversList;

    public DriversConfigurationPanel() {
        this.initComponents();
        List<String> drivers = PropertiesLoader.readDrivers();
        this.vecDrivers = new Vector<String>(drivers);
        this.MscspOnCheckB.setSelected(PropertiesLoader.useMscsp());
        this.jlDriversList.setListData(this.vecDrivers);
        this.checkBoxPdfPreview.setSelected(usePdfPreview);
        this.checkBoxAppearance.setSelected(signatureAppearance);
        this.checkBoxPdfPreview.setEnabled(signatureAppearance);
    }

    public static boolean getUsePdfPreview() {
        return usePdfPreview;
    }

    public static boolean getSignatureAppearance() {
        return signatureAppearance;
    }

    private void initComponents() {
        JPanel jPanel1 = new JPanel();
        JLabel jLabel2 = new JLabel();
        JButton jbtnChooseDriver = new JButton();
        JScrollPane jScrollPane1 = new JScrollPane();
        this.jlDriversList = new JList();
        JButton jbtnRemoveDriver = new JButton();
        this.MscspOnCheckB = new JCheckBox("MSCSP ON");
        this.checkBoxPdfPreview = new JCheckBox("Pdf Preview ON");
        this.checkBoxAppearance = new JCheckBox("Signature Appearance ON");
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        jPanel1.setBorder(BorderFactory.createTitledBorder(bundle.getString("propertiesconfiguration.label.driver_configuration")));
        jLabel2.setText(bundle.getString("propertiesconfiguration.label.desc_text"));
        jbtnChooseDriver.setText(bundle.getString("propertiesconfiguration.btn.choose_driver"));
        jbtnChooseDriver.addActionListener(this::jbtnChooseDriverActionPerformed);
        jScrollPane1.setViewportView(this.jlDriversList);
        jbtnRemoveDriver.setText(bundle.getString("pcp.btn.remove_driver"));
        jbtnRemoveDriver.addActionListener(this::jbtnRemoveDriverActionPerformed);
        JButton jbtnRefreshDrivers = new JButton();
        jbtnRefreshDrivers.setText(bundle.getString("propertiesconfiguration.btn.refresh_drivers"));
        jbtnRefreshDrivers.addActionListener(this::jbtnRefreshDriversActionPerformed);
        if (!Single.isWindows) {
            this.MscspOnCheckB.setVisible(false);
        }
        this.MscspOnCheckB.addActionListener(this::MscspOnCheckBActionPerformed);
        this.checkBoxPdfPreview.addItemListener(e -> {
            usePdfPreview = e.getStateChange() == 1;
        });
        this.checkBoxAppearance.addActionListener(this::checkBoxAppearanceActionPerformed);
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jScrollPane1, -1, 433, Short.MAX_VALUE).addComponent(jLabel2).addComponent(this.MscspOnCheckB).addComponent(this.checkBoxAppearance, GroupLayout.Alignment.TRAILING).addComponent(this.checkBoxPdfPreview, GroupLayout.Alignment.TRAILING).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addComponent(jbtnChooseDriver).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jbtnRefreshDrivers).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jbtnRemoveDriver))).addContainerGap());
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addComponent(jLabel2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jScrollPane1, -2, 140, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.MscspOnCheckB).addComponent(this.checkBoxAppearance)).addComponent(this.checkBoxPdfPreview).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jbtnChooseDriver).addComponent(jbtnRemoveDriver).addComponent(jbtnRefreshDrivers)).addContainerGap());
        jbtnRefreshDrivers.getAccessibleContext().setAccessibleName("Refresh Drivers");
        jbtnRefreshDrivers.getAccessibleContext().setAccessibleDescription("");
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -2, Short.MAX_VALUE).addContainerGap());
        layout.setVerticalGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -2, Short.MAX_VALUE).addContainerGap());
    }

    private void jbtnChooseDriverActionPerformed(ActionEvent evt) {
        int result;
        FileNameExtensionFilter filterDriver = null;
        String driverPath = PropertiesLoader.getProperties("PKCS11").getProperty("defaultDriverPath");
        if (Single.isWindows) {
            filterDriver = new FileNameExtensionFilter("Driver file (.dll)", "dll");
        } else if (Single.isLinux) {
            filterDriver = new FileNameExtensionFilter("Driver file (.so)", "so");
        }
        JFileChooser jfc = driverPath != null ? new JFileChooser(new File(driverPath)) : new JFileChooser();
        jfc.setFileSelectionMode(0);
        jfc.setAcceptAllFileFilterUsed(false);
        if (filterDriver != null) {
            jfc.addChoosableFileFilter(filterDriver);
        }
        if ((result = jfc.showOpenDialog(this)) == 0) {
            final String driverName = jfc.getSelectedFile().getAbsolutePath();
            logger.debug("loading driver {}", (Object)driverName);
            if (this.vecDrivers.add(driverName)) {
                SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

                    @Override
                    protected ProgressBarModel doInBackground() {
                        this.firePropertyChange("currentOperation", null, DriversConfigurationPanel.this.rbundle.getString("drivers.progress.set_driver"));
                        CardReaderManager.get().loadDriver(driverName);
                        DriversConfigurationPanel.this.jlDriversList.setListData(DriversConfigurationPanel.this.vecDrivers);
                        this.setProgress(100);
                        return new ProgressBarModel(DriversConfigurationPanel.this.rbundle.getString("info_msg.driver_property_changed"), 1);
                    }
                };
                ProgressBarDialog pbd = new ProgressBarDialog(worker);
                pbd.setLocationRelativeTo(this);
                pbd.setVisible(true);
            }
        }
    }

    private void jbtnRemoveDriverActionPerformed(ActionEvent evt) {
        if (this.jlDriversList.getSelectedValue() == null) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("error_msg.driver_not_selected"), this.rbundle.getString("error_msg.driver_not_selected"), 0);
            return;
        }
        String driverToRemove = this.jlDriversList.getSelectedValue();
        if (this.vecDrivers.remove(driverToRemove)) {
            CardReaderManager.get().removeDriver(driverToRemove);
        }
        this.jlDriversList.setListData(this.vecDrivers);
        JOptionPane.showMessageDialog(this, this.rbundle.getString("info_msg.driver_succes_removed"), this.rbundle.getString("info_msg.driver_succes_removed"), 1);
    }

    private void jbtnRefreshDriversActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() throws Exception {
                List<String> driverLibs = PropertiesLoader.readDrivers();
                this.firePropertyChange("currentOperation", null, DriversConfigurationPanel.this.rbundle.getString("drivers.progress.refresh_drivers"));
                CardReaderManager.get().stopListening();
                CardReaderManager.get().removeAllDrivers();
                CardReaderManager.get().loadDriverLibList(driverLibs);
                CardReaderManager.get().startListeners();
                this.setProgress(100);
                return new ProgressBarModel(DriversConfigurationPanel.this.rbundle.getString("drivers.progress.refreshed_drivers"), 1);
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    private void MscspOnCheckBActionPerformed(ActionEvent evt) {
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                String msg = "MSCSP ON!";
                if (DriversConfigurationPanel.this.MscspOnCheckB.isSelected()) {
                    if (!PropertiesLoader.useMscsp()) {
                        if (Single.isWindows) {
                            MSCSPSecurityProvider msCspSecurityProvider = new MSCSPSecurityProvider();
                            SecurityOperationsProviderManager.registerProvider("MSCSP", msCspSecurityProvider);
                            GlobalCertificateProvider.get().registerProvider(msCspSecurityProvider, false);
                            GlobalCertificateProvider.get().refreshProviderCertificates();
                        }
                        PropertiesLoader.setUseMscsp(true);
                    }
                } else if (PropertiesLoader.useMscsp()) {
                    if (Single.isWindows) {
                        GlobalCertificateProvider.get().removeProvider("MSCSP");
                        SecurityOperationsProviderManager.removeProvider("MSCSP");
                        GlobalCertificateProvider.get().refreshProviderCertificates();
                    }
                    msg = "MSCSP OFF!";
                    PropertiesLoader.setUseMscsp(false);
                }
                this.setProgress(100);
                return new ProgressBarModel(msg, 1);
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    private void checkBoxAppearanceActionPerformed(ActionEvent evt) {
        if (this.checkBoxAppearance.isSelected()) {
            signatureAppearance = true;
            this.checkBoxPdfPreview.setEnabled(true);
        } else {
            signatureAppearance = false;
            this.checkBoxPdfPreview.setEnabled(false);
        }
    }

    @Override
    public void onSaveConfiguration() {
        StringBuilder allDrivers = new StringBuilder();
        for (String driver : this.vecDrivers) {
            allDrivers.append(driver);
            allDrivers.append("|");
        }
        allDrivers.setLength(allDrivers.length() - 1);
        PropertiesLoader.setProperty("PKCS11", "driver_lib", allDrivers.toString());
    }
}

