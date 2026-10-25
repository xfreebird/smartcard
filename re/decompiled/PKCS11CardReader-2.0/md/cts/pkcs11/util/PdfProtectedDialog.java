/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 */
package md.cts.pkcs11.util;

import java.awt.Dimension;
import java.awt.Toolkit;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.LayoutStyle;
import md.ghesar.Resource;

public final class PdfProtectedDialog
extends JFrame {
    private JButton jButton1;
    private JLabel jLabel1;

    public PdfProtectedDialog() {
        this.initComponents();
        PdfProtectedDialog temp = this;
        temp.addWindowListener(new WindowAdapter(){

            @Override
            public void windowClosing(WindowEvent e) {
                e.getWindow().dispose();
            }
        });
        this.jButton1.addActionListener(e -> temp.dispose());
        String message = ResourceBundle.getBundle("translations1").getString("error.pdfprotected");
        this.jLabel1.setText(message);
    }

    private void initComponents() {
        this.jLabel1 = new JLabel();
        this.jButton1 = new JButton();
        this.setDefaultCloseOperation(3);
        this.jButton1.setText("OK");
        this.jButton1.setHorizontalAlignment(0);
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(this.jLabel1, -1, -1, Short.MAX_VALUE).addContainerGap()).addGroup(layout.createSequentialGroup().addGap(152, 152, 152).addComponent(this.jButton1).addContainerGap(-1, Short.MAX_VALUE)));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addGap(18, 18, 18).addComponent(this.jLabel1, -2, 34, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.jButton1).addContainerGap(9, Short.MAX_VALUE)));
        this.pack();
    }

    public void init() {
        this.setDefaultCloseOperation(2);
        this.setIconImage(Resource.getImage((String)"/error_icon.png"));
        Dimension dim = Toolkit.getDefaultToolkit().getScreenSize();
        this.setLocation(dim.width / 2 - this.getSize().width / 2, dim.height / 2 - this.getSize().height / 2);
        this.setTitle("Pdf Protected");
        this.setSize(new Dimension(270, 130));
        this.setVisible(true);
    }
}

