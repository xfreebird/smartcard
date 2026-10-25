/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 */
package md.cts.moldsign.clientcardmanager.ui.main;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Container;
import java.util.ResourceBundle;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.KeyStroke;
import md.cts.moldsign.clientcardmanager.panels.MainPanel;
import md.ghesar.Resource;

public final class MainScreen
extends JFrame {
    private MainPanel mpanel;

    public MainScreen(Long slotGlobalId) {
        this.setDefaultCloseOperation(2);
        this.getRootPane().registerKeyboardAction(e -> this.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        this.initComponents(slotGlobalId);
        this.pack();
        this.setLocationRelativeTo(null);
        this.setVisible(true);
    }

    private void initComponents(Long slotGlobalId) {
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("mainframe.card_info"));
        this.setIconImage(Resource.getImage((String)"/applogo.png"));
        JLabel jLabel1 = new JLabel();
        jLabel1.setOpaque(true);
        jLabel1.setBackground(new Color(15, 24, 56));
        jLabel1.setIcon(new ImageIcon(Resource.getImage((String)"/MoldSign 2.jpg")));
        this.mpanel = new MainPanel(slotGlobalId);
        this.mpanel.refreshCardInfo();
        JPanel layerHolder = new JPanel();
        layerHolder.setLayout(new BorderLayout());
        layerHolder.add((Component)this.mpanel, "Center");
        Container pane = this.getContentPane();
        pane.add((Component)jLabel1, "First");
        pane.add((Component)layerHolder, "Center");
    }
}

