/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.popups;

import java.awt.Frame;
import java.awt.event.ActionEvent;
import java.text.MessageFormat;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.LayoutStyle;

public class FileExistsSelectAction
extends JDialog {
    final ResourceBundle rBundle = ResourceBundle.getBundle("translations");
    private Action action = Action.OVERWRITE;
    private JButton btnCoSign;
    private JButton btnOverwrite;
    private JLabel lblMessage;

    public FileExistsSelectAction(String fileName) {
        this((Frame)null, true);
        this.lblMessage.setText(MessageFormat.format(this.rBundle.getString("popup.file_exisists_action.message"), fileName));
    }

    public FileExistsSelectAction(Frame parent, boolean modal) {
        super(parent, modal);
        this.initComponents();
    }

    public synchronized Action getResult() {
        return this.action;
    }

    private void initComponents() {
        this.lblMessage = new JLabel();
        this.btnOverwrite = new JButton();
        this.btnCoSign = new JButton();
        this.setDefaultCloseOperation(0);
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.lblMessage.setText(bundle.getString("popup.file_exisists_action.message"));
        this.btnOverwrite.setText(bundle.getString("popup.file_exisists_action.overwrite"));
        this.btnOverwrite.addActionListener(this::btnOverwriteActionPerformed);
        this.btnCoSign.setText(bundle.getString("popup.file_exisists_action.cosign"));
        this.btnCoSign.addActionListener(this::btnCoSignActionPerformed);
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.TRAILING).addComponent(this.lblMessage).addGroup(layout.createSequentialGroup().addComponent(this.btnOverwrite, -2, 186, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.btnCoSign, -2, 184, -2))).addContainerGap()));
        layout.linkSize(0, this.btnCoSign, this.btnOverwrite);
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(this.lblMessage, -1, 50, Short.MAX_VALUE).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.btnCoSign).addComponent(this.btnOverwrite)).addContainerGap()));
        this.pack();
    }

    private void btnOverwriteActionPerformed(ActionEvent evt) {
        this.action = Action.OVERWRITE;
        this.setVisible(false);
    }

    private void btnCoSignActionPerformed(ActionEvent evt) {
        this.action = Action.COSIGN;
        this.setVisible(false);
    }

    public static enum Action {
        OVERWRITE,
        COSIGN;

    }
}

