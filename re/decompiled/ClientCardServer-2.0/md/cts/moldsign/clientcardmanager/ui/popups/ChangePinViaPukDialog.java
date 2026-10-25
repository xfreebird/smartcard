/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.ui.popups;

import java.awt.Font;
import java.awt.Frame;
import java.awt.event.ActionEvent;
import java.util.Arrays;
import java.util.ResourceBundle;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPasswordField;
import javax.swing.JSeparator;
import javax.swing.KeyStroke;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import md.cts.moldsign.clientcardmanager.models.ProgressBarModel;
import md.cts.moldsign.clientcardmanager.panels.MainPanel;
import md.cts.moldsign.clientcardmanager.ui.popups.ProgressBarDialog;
import md.cts.pkcs11.cards.Card;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.PinLockedException;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ChangePinViaPukDialog
extends JDialog {
    private static final Logger logger = LoggerFactory.getLogger(ChangePinViaPukDialog.class);
    private final ResourceBundle rbundle = ResourceBundle.getBundle("translations");
    private String crdName;
    private Card card;
    private JButton btnChangePinOk;
    private JPasswordField jpfConfirmNewPin;
    private JPasswordField jpfEnterNewPin;
    private JPasswordField jpfEnterPuk;
    private JLabel lblNewPinDescription;

    public ChangePinViaPukDialog(Frame parent, boolean modal, MainPanel pnl) {
        super(parent, modal);
        this.setDefaultCloseOperation(2);
        this.getRootPane().registerKeyboardAction(e -> this.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        this.initComponents();
        this.pack();
        this.getRootPane().setDefaultButton(this.btnChangePinOk);
    }

    private void initComponents() {
        JLabel lblChangePinSubtitle = new JLabel();
        JSeparator jSeparator1 = new JSeparator();
        JLabel lblEnterPuk = new JLabel();
        this.lblNewPinDescription = new JLabel();
        JLabel lblEnterNewPin = new JLabel();
        this.jpfEnterPuk = new JPasswordField();
        this.jpfEnterNewPin = new JPasswordField();
        JLabel lblConfirmNewPin = new JLabel();
        this.jpfConfirmNewPin = new JPasswordField();
        this.btnChangePinOk = new JButton();
        JButton btnCancelPin = new JButton();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        this.setTitle(bundle.getString("changepinviapuk.window_title.change_pin"));
        this.setIconImage(Resource.getImage((String)"/applogo.png"));
        this.setLocationByPlatform(true);
        lblChangePinSubtitle.setFont(new Font("Ubuntu", 1, 15));
        lblChangePinSubtitle.setText(bundle.getString("changepinviapuk.label.subtitle"));
        lblEnterPuk.setText(bundle.getString("changepinviapuk.label.enter_puk"));
        this.lblNewPinDescription.setText(bundle.getString("changepin.label.new_pin_description"));
        lblEnterNewPin.setText(bundle.getString("changepin.label.enter_new_pin"));
        lblConfirmNewPin.setText(bundle.getString("changepin.label.confirm_new_pin"));
        this.btnChangePinOk.setText(bundle.getString("button.ok"));
        btnCancelPin.setText(bundle.getString("button.cancel"));
        this.btnChangePinOk.addActionListener(this::btnChangePinOkActionPerformed);
        btnCancelPin.addActionListener(this::btnCancelPinActionPerformed);
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(lblEnterNewPin).addComponent(lblConfirmNewPin)).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, -1, Short.MAX_VALUE).addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(this.jpfEnterNewPin, GroupLayout.Alignment.TRAILING, -2, 68, -2).addComponent(this.jpfConfirmNewPin, GroupLayout.Alignment.TRAILING, -2, 68, -2))).addComponent(jSeparator1).addComponent(lblChangePinSubtitle, -2, 196, -2).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addComponent(this.btnChangePinOk).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnCancelPin)).addGroup(layout.createSequentialGroup().addComponent(lblEnterPuk).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, -1, Short.MAX_VALUE).addComponent(this.jpfEnterPuk, -2, 68, -2)).addComponent(this.lblNewPinDescription, -1, 322, Short.MAX_VALUE)).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(lblChangePinSubtitle).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jSeparator1, -2, -1, -2).addGap(18, 18, 18).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblEnterPuk).addComponent(this.jpfEnterPuk, -2, -1, -2)).addGap(18, 18, 18).addComponent(this.lblNewPinDescription).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jpfEnterNewPin, -2, -1, -2).addComponent(lblEnterNewPin)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(lblConfirmNewPin).addComponent(this.jpfConfirmNewPin, -2, -1, -2)).addGap(18, 18, 18).addGroup(layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(btnCancelPin).addComponent(this.btnChangePinOk)).addContainerGap(12, Short.MAX_VALUE)));
    }

    private void btnCancelPinActionPerformed(ActionEvent evt) {
        this.dispose();
    }

    private void btnChangePinOkActionPerformed(ActionEvent evt) {
        if (this.jpfEnterPuk.getPassword().length == 0) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("changepinviapuk.error_msg.enter_puk"), this.rbundle.getString("changepinviapuk.error_msg.enter_puk"), 0);
            this.jpfEnterPuk.requestFocus();
            return;
        }
        if (this.jpfEnterNewPin.getPassword().length == 0) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("changepinviapuk.error_msg.enter_new_pin"), this.rbundle.getString("changepinviapuk.error_msg.enter_new_pin"), 0);
            this.jpfEnterNewPin.requestFocus();
            return;
        }
        if (this.jpfConfirmNewPin.getPassword().length == 0) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("changepinviapuk.error_msg.confirm_new_pin"), this.rbundle.getString("changepinviapuk.error_msg.confirm_new_pin"), 0);
            this.jpfConfirmNewPin.requestFocus();
            return;
        }
        if (!Arrays.equals(this.jpfEnterNewPin.getPassword(), this.jpfConfirmNewPin.getPassword())) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("changepinviapuk.error_msg.pin_dont_match"), this.rbundle.getString("changepinviapuk.error_msg.pin_dont_match"), 0);
            this.jpfEnterNewPin.requestFocus();
            this.jpfEnterNewPin.selectAll();
            return;
        }
        if (this.jpfEnterNewPin.getPassword().length < 4 || this.jpfEnterNewPin.getPassword().length > 8) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("changepin.label.new_pin_description"), this.rbundle.getString("changepin.label.new_pin_description"), 0);
            this.jpfEnterNewPin.requestFocus();
            this.jpfEnterNewPin.selectAll();
            return;
        }
        String newPinString = new String(this.jpfEnterNewPin.getPassword());
        if (!newPinString.matches("[0-9]*")) {
            JOptionPane.showMessageDialog(this, this.rbundle.getString("changepin.label.new_pin_description"), this.rbundle.getString("changepin.label.new_pin_description"), 0);
            this.jpfEnterNewPin.requestFocus();
            this.jpfEnterNewPin.selectAll();
            return;
        }
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() throws Exception {
                try {
                    this.firePropertyChange("currentOperation", null, ChangePinViaPukDialog.this.rbundle.getString("changepinviapuk.info_msg.changing_pin"));
                    ChangePinViaPukDialog.this.card.resetPin(ChangePinViaPukDialog.this.jpfEnterPuk.getPassword(), ChangePinViaPukDialog.this.jpfEnterNewPin.getPassword());
                    this.firePropertyChange("currentOperation", null, ChangePinViaPukDialog.this.rbundle.getString("changepinviapuk.info_msg.pin_changed"));
                }
                catch (InvalidPinException ex) {
                    logger.error("", (Throwable)ex);
                    return new ProgressBarModel(ChangePinViaPukDialog.this.rbundle.getString("changepuk.error_msg.incorrect_puk"), 0);
                }
                catch (PinLockedException ex) {
                    logger.error("", (Throwable)ex);
                    return new ProgressBarModel(ChangePinViaPukDialog.this.rbundle.getString("changepuk.error_msg.puk_locked"), 0);
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                    return new ProgressBarModel(ChangePinViaPukDialog.this.rbundle.getString("changepuk.error_msg.pin_len"), 0);
                }
                this.setProgress(100);
                ChangePinViaPukDialog.this.dispose();
                return new ProgressBarModel(ChangePinViaPukDialog.this.rbundle.getString("changepin.info_msg.pin_changed"), 1);
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    public void setCrdName(String name) {
        this.crdName = name;
    }

    public void initiateCustomStringForFS() {
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        if (this.crdName.contains("FS USB")) {
            this.lblNewPinDescription.setText(bundle.getString("changepin.label.new_pin_description_fs"));
        }
    }

    public void refreshCardInfo(Card c) {
        this.card = c;
    }
}

