/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.ui.popups;

import java.awt.Color;
import java.io.IOException;
import java.net.URL;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JEditorPane;
import javax.swing.JLabel;
import javax.swing.JScrollPane;
import javax.swing.KeyStroke;
import javax.swing.LayoutStyle;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AboutPageDialog
extends JDialog {
    private static final Logger logger = LoggerFactory.getLogger(AboutPageDialog.class);
    private JEditorPane jepAboutDescription;
    private JLabel version;

    public AboutPageDialog() {
        this.setDefaultCloseOperation(2);
        this.getRootPane().registerKeyboardAction(e -> this.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        this.initComponents();
        this.pack();
        URL url = AboutPageDialog.class.getResource("/AboutPage.html");
        try {
            this.jepAboutDescription.setPage(url);
            ResourceBundle rbundle = ResourceBundle.getBundle("translations");
            String versionName = rbundle.getString("application.version");
            String versionNumber = "2.4.12";
            String versionLabelText = "<html>" + versionName + " <font color='green'>" + versionNumber + "</font></html>";
            this.version.setText(versionLabelText);
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
    }

    private void initComponents() {
        JLabel imgAboutPage = new JLabel();
        imgAboutPage.setOpaque(true);
        imgAboutPage.setBackground(new Color(15, 24, 56));
        imgAboutPage.setIcon(new ImageIcon(Resource.getImage((String)"/MoldSign 2.jpg")));
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        JButton btnClose = new JButton();
        btnClose.setText(bundle.getString("aboutpagepanel.button.close"));
        btnClose.addActionListener(e -> this.dispose());
        JScrollPane jScrollPane2 = new JScrollPane();
        this.jepAboutDescription = new JEditorPane();
        this.version = new JLabel();
        this.setTitle(bundle.getString("aboutpagedialog.title"));
        this.setIconImage(Resource.getImage((String)"/applogo.png"));
        this.jepAboutDescription.setEditable(false);
        this.jepAboutDescription.setBorder(null);
        jScrollPane2.setViewportView(this.jepAboutDescription);
        this.version.setText("jLabel1");
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.TRAILING).addGroup(layout.createSequentialGroup().addComponent(this.version).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, -1, Short.MAX_VALUE).addComponent(btnClose)).addComponent(imgAboutPage, GroupLayout.Alignment.LEADING, -1, -1, Short.MAX_VALUE).addComponent(jScrollPane2)).addGap(12, 12, 12)));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(imgAboutPage).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(jScrollPane2, -1, 225, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnClose).addComponent(this.version)).addContainerGap()));
    }
}

