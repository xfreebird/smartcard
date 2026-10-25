/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.clientcardmanager.ui.configuration.popups;

import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.DefaultComboBoxModel;
import javax.swing.GroupLayout;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.LayoutStyle;
import md.cts.moldsign.clientcardmanager.properties.PropertiesLoader;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.ConfigurationSaveInterface;

public class LanguageConfigurationPanel
extends JPanel
implements ConfigurationSaveInterface {
    final DefaultComboBoxModel<LanguageValue> langModel = new DefaultComboBoxModel();

    public LanguageConfigurationPanel() {
        LanguageValue lvEn = new LanguageValue("", "English");
        LanguageValue lvRo = new LanguageValue("ro", "Romanian");
        LanguageValue lvRu = new LanguageValue("ru", "Russian");
        String locale = PropertiesLoader.getProperties("Locale").getProperty("Locale", "");
        this.langModel.addElement(lvEn);
        if (locale.equals(lvEn.getLocale())) {
            this.langModel.setSelectedItem(lvEn);
        }
        this.langModel.addElement(lvRo);
        if (locale.equals(lvRo.getLocale())) {
            this.langModel.setSelectedItem(lvRo);
        }
        this.langModel.addElement(lvRu);
        if (locale.equals(lvRu.getLocale())) {
            this.langModel.setSelectedItem(lvRu);
        }
        this.initComponents();
    }

    private void initComponents() {
        JPanel jPanel1 = new JPanel();
        JLabel lblLanguages = new JLabel();
        JComboBox<LanguageValue> cmbLanguages = new JComboBox<LanguageValue>();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        jPanel1.setBorder(BorderFactory.createTitledBorder(bundle.getString("propertiesconfiguration.label.language_configuration")));
        lblLanguages.setLabelFor(cmbLanguages);
        lblLanguages.setText(bundle.getString("propertiesconfiguration.label.lang_desc"));
        cmbLanguages.setModel(this.langModel);
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addComponent(lblLanguages).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(cmbLanguages, 0, 358, Short.MAX_VALUE).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(cmbLanguages, -2, -1, -2).addComponent(lblLanguages)).addContainerGap(158, Short.MAX_VALUE)));
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
    }

    @Override
    public void onSaveConfiguration() {
        LanguageValue lv = (LanguageValue)this.langModel.getSelectedItem();
        if (lv != null) {
            PropertiesLoader.setProperty("Locale", "Locale", lv.getLocale());
        }
    }

    private static class LanguageValue {
        private final String locale;
        private final String name;

        public LanguageValue(String locale, String name) {
            this.locale = locale;
            this.name = name;
        }

        public String getLocale() {
            return this.locale;
        }

        public String toString() {
            return this.name;
        }
    }
}

