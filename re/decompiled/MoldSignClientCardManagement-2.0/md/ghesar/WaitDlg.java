/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.ghesar;

import java.awt.Container;
import java.awt.Dialog;
import java.awt.Dimension;
import java.awt.Window;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.KeyStroke;
import javax.swing.SwingWorker;
import md.cts.moldsign.msccm.rest.clients.ConnectionChecker;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class WaitDlg {
    private static final Logger logger = LoggerFactory.getLogger(WaitDlg.class);
    private final JFrame owner;
    private JDialog dlg;

    private WaitDlg(JFrame owner) {
        this.owner = owner;
    }

    public static void display(JFrame owner) {
        WaitDlg view = new WaitDlg(owner);
        view.createWork();
        view.init();
    }

    public void createWork() {
        SwingWorker<Boolean, Void> worker = new SwingWorker<Boolean, Void>(){

            @Override
            protected Boolean doInBackground() {
                return ConnectionChecker.canConnectToServer();
            }

            @Override
            protected void done() {
                boolean result = false;
                try {
                    result = (Boolean)this.get();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
                WaitDlg.this.dlg.dispose();
                if (!result) {
                    WaitDlg.this.owner.dispose();
                }
            }
        };
        worker.execute();
    }

    private void init() {
        this.dlg = new JDialog((Window)this.owner, "MoldSign", Dialog.ModalityType.APPLICATION_MODAL);
        this.dlg.setDefaultCloseOperation(2);
        this.dlg.getRootPane().registerKeyboardAction(e -> this.dlg.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        this.dlg.setIconImage(Resource.getImage("/applogo.png"));
        JButton btnCancel = new JButton("Close");
        btnCancel.addActionListener(e -> {
            this.dlg.dispose();
            this.owner.dispose();
        });
        JLabel label1 = new JLabel("Please start the server. Waiting for the server application to be up ...", 0);
        Container pane = this.dlg.getContentPane();
        GroupLayout layout = new GroupLayout(pane);
        pane.setLayout(layout);
        layout.setHorizontalGroup(layout.createSequentialGroup().addGap(12).addGroup(layout.createParallelGroup().addComponent(label1, -2, -1, Short.MAX_VALUE).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addComponent(btnCancel))).addGap(12));
        layout.setVerticalGroup(layout.createSequentialGroup().addGap(12).addComponent(label1, -2, -1, Short.MAX_VALUE).addGap(12).addGroup(layout.createParallelGroup().addComponent(btnCancel)).addGap(12));
        this.dlg.setMinimumSize(new Dimension(310, 96));
        this.dlg.pack();
        this.dlg.setLocationRelativeTo(this.owner);
        this.dlg.setVisible(true);
    }
}

