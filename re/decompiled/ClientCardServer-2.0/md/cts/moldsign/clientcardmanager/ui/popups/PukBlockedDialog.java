/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 */
package md.cts.moldsign.clientcardmanager.ui.popups;

import java.awt.Dimension;
import java.awt.Toolkit;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.LayoutStyle;
import md.cts.moldsign.clientcardmanager.start.ClientCardManager;
import md.ghesar.Resource;

public class PukBlockedDialog
extends JFrame {
    private JButton jButton1;

    public PukBlockedDialog() {
        this.setDefaultCloseOperation(2);
        this.initComponents();
        this.pack();
        PukBlockedDialog temp = this;
        temp.addWindowListener(new WindowAdapter(){

            @Override
            public void windowClosing(WindowEvent e) {
                e.getWindow().dispose();
            }
        });
        this.jButton1.addActionListener(e -> temp.dispose());
    }

    private void initComponents() {
        JLabel jLabel1 = new JLabel();
        this.jButton1 = new JButton();
        String message = ClientCardManager.exceptionBundle.getString("exception.general.puk_locked");
        jLabel1.setText(message);
        this.jButton1.setText("OK");
        this.jButton1.setHorizontalAlignment(0);
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jLabel1, -1, -1, Short.MAX_VALUE).addContainerGap()).addGroup(layout.createSequentialGroup().addGap(208, 208, 208).addComponent(this.jButton1).addContainerGap(-1, Short.MAX_VALUE)));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addGap(12, 12, 12).addComponent(jLabel1, -2, 34, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.jButton1).addContainerGap(15, Short.MAX_VALUE)));
    }

    public void init() {
        this.setIconImage(Resource.getImage((String)"/error_icon.png"));
        Dimension dim = Toolkit.getDefaultToolkit().getScreenSize();
        this.setLocation(dim.width / 2 - this.getSize().width / 2, dim.height / 2 - this.getSize().height / 2);
        this.setTitle("Invalid Puk");
        this.setVisible(true);
    }
}

