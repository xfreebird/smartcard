/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.panels.tabs;

import java.awt.Color;
import java.awt.event.ActionEvent;
import java.awt.event.ItemEvent;
import java.net.URI;
import java.util.ResourceBundle;
import javax.swing.BorderFactory;
import javax.swing.ButtonGroup;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.JSeparator;
import javax.swing.JTextField;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import md.cts.moldsign.msccm.TabPanel;
import md.cts.moldsign.msccm.exceptions.ServerException;
import md.cts.moldsign.msccm.models.ProgressBarModel;
import md.cts.moldsign.msccm.popups.ProgressBarDialog;
import md.cts.moldsign.msccm.rest.clients.SafeDeleteClient;
import md.cts.moldsign.transferobjects.models.SafeDeleteInputModel;
import md.cts.moldsign.transferobjects.models.SafeDeleteResponseModel;

public class SafeDeletePanel
extends JPanel
implements TabPanel {
    private final ResourceBundle resource = ResourceBundle.getBundle("translations");
    private JTextField jtfFilePath;
    private JTextField jtfNbrRandomAttempts;
    private JRadioButton rbtnDod3;
    private JRadioButton rbtnDod7;
    private JRadioButton rbtnPRN;
    private JRadioButton rbtnPeterGutmann;

    public SafeDeletePanel() {
        this.initComponents();
        this.initRadioButtons();
    }

    private void initComponents() {
        JPanel jPanel1 = new JPanel();
        JLabel jLabel1 = new JLabel();
        this.jtfFilePath = new JTextField();
        JButton btnBrowse = new JButton();
        JPanel jPanel2 = new JPanel();
        this.rbtnPeterGutmann = new JRadioButton();
        this.rbtnDod3 = new JRadioButton();
        this.rbtnDod7 = new JRadioButton();
        this.rbtnPRN = new JRadioButton();
        this.jtfNbrRandomAttempts = new JTextField();
        JLabel jLabel2 = new JLabel();
        JButton btnDelete = new JButton();
        JSeparator jSeparator1 = new JSeparator();
        ResourceBundle bundle = ResourceBundle.getBundle("translations");
        jPanel1.setBorder(BorderFactory.createTitledBorder(null, bundle.getString("safedelete.title.border"), 0, 0, null, new Color(0, 0, 0)));
        jLabel1.setText(bundle.getString("lbl.selectFileToDelete"));
        btnBrowse.setText(bundle.getString("btn.browse"));
        btnBrowse.addActionListener(this::btnBrowseActionPerformed);
        jPanel2.setBorder(BorderFactory.createTitledBorder(null, bundle.getString("title.border.selectTypeOfDeletion"), 0, 0, null, new Color(0, 0, 0)));
        this.rbtnPeterGutmann.setText("Peter Gutmann");
        this.rbtnPeterGutmann.setName("PeterGutmann");
        this.rbtnDod3.setText("DoD3");
        this.rbtnDod3.setName("DoD3");
        this.rbtnDod7.setText("DoD7");
        this.rbtnDod7.setName("DoD7");
        this.rbtnPRN.setText("Pseudo Random Number -  ");
        this.rbtnPRN.setName("PseudoRandomNumber");
        this.rbtnPRN.addItemListener(this::onItemStateChange);
        this.jtfNbrRandomAttempts.setEnabled(false);
        jLabel2.setText(bundle.getString("lbl.nbrRandomAttempts"));
        GroupLayout jPanel2Layout = new GroupLayout(jPanel2);
        jPanel2.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel2Layout.createSequentialGroup().addContainerGap().addGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel2Layout.createSequentialGroup().addComponent(this.rbtnPRN).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(jLabel2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(this.jtfNbrRandomAttempts, -2, 67, -2)).addComponent(this.rbtnPeterGutmann).addComponent(this.rbtnDod3).addComponent(this.rbtnDod7)).addContainerGap(147, Short.MAX_VALUE)));
        jPanel2Layout.setVerticalGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel2Layout.createSequentialGroup().addComponent(this.rbtnPeterGutmann).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.rbtnDod3).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.rbtnDod7).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, 3, Short.MAX_VALUE).addGroup(jPanel2Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(this.jtfNbrRandomAttempts, -2, -1, -2).addComponent(jLabel2).addComponent(this.rbtnPRN))));
        btnDelete.setText(bundle.getString("btn.delete"));
        btnDelete.addActionListener(this::btnDeleteActionPerformed);
        GroupLayout jPanel1Layout = new GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addComponent(jPanel2, -1, -1, Short.MAX_VALUE).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addGap(0, 0, Short.MAX_VALUE).addComponent(btnDelete)).addGroup(GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup().addComponent(jLabel1).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.jtfFilePath).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED).addComponent(btnBrowse)).addComponent(jSeparator1)).addContainerGap()));
        jPanel1Layout.setVerticalGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(jPanel1Layout.createSequentialGroup().addContainerGap().addGroup(jPanel1Layout.createParallelGroup(GroupLayout.Alignment.BASELINE).addComponent(jLabel1).addComponent(this.jtfFilePath, -2, -1, -2).addComponent(btnBrowse)).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(jPanel2, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.RELATED, 70, Short.MAX_VALUE).addComponent(jSeparator1, -2, -1, -2).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(btnDelete)));
        GroupLayout layout = new GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addComponent(jPanel1, -1, -1, Short.MAX_VALUE).addContainerGap()));
    }

    private void btnDeleteActionPerformed(ActionEvent evt) {
        if ("".equals(this.jtfFilePath.getText())) {
            JOptionPane.showMessageDialog(this, this.resource.getString("delete.err_msg.please_select_file_to_delete"), this.resource.getString("delete.err_msg.please_select_file_to_delete"), 0);
            this.jtfFilePath.requestFocus();
            return;
        }
        SwingWorker<ProgressBarModel, String> worker = new SwingWorker<ProgressBarModel, String>(){

            @Override
            protected ProgressBarModel doInBackground() {
                this.firePropertyChange("currentOperation", null, SafeDeletePanel.this.resource.getString("delete.progress.setting_params"));
                SafeDeleteInputModel sdim = new SafeDeleteInputModel();
                sdim.setFile(SafeDeletePanel.this.jtfFilePath.getText());
                if (SafeDeletePanel.this.rbtnPeterGutmann.isSelected()) {
                    sdim.setAlgorithm(SafeDeletePanel.this.rbtnPeterGutmann.getName());
                }
                if (SafeDeletePanel.this.rbtnDod3.isSelected()) {
                    sdim.setAlgorithm(SafeDeletePanel.this.rbtnDod3.getName());
                }
                if (SafeDeletePanel.this.rbtnDod7.isSelected()) {
                    sdim.setAlgorithm(SafeDeletePanel.this.rbtnDod7.getName());
                }
                if (SafeDeletePanel.this.rbtnPRN.isSelected()) {
                    sdim.setAlgorithm(SafeDeletePanel.this.rbtnPRN.getName());
                    try {
                        int nbr = Integer.parseInt(SafeDeletePanel.this.jtfNbrRandomAttempts.getText());
                        if (nbr < 0) {
                            return new ProgressBarModel(SafeDeletePanel.this.resource.getString("delete.err_msg.must_be_positive"), 0);
                        }
                        sdim.setNrRetries(nbr);
                    }
                    catch (NumberFormatException nfe) {
                        return new ProgressBarModel(SafeDeletePanel.this.resource.getString("delete.err_msg.must_be_number"), 0);
                    }
                }
                SafeDeleteClient sdc = new SafeDeleteClient();
                this.firePropertyChange("currentOperation", null, SafeDeletePanel.this.resource.getString("delete.deleteing"));
                URI uri2 = sdc.safeDeletePost(sdim);
                if (uri2 != null) {
                    SafeDeleteResponseModel sdrm;
                    try {
                        sdrm = sdc.safeDeleteGet(uri2);
                    }
                    catch (ServerException ex) {
                        return new ProgressBarModel(SafeDeletePanel.this.resource.getString("sign.err_msg.sign_failed") + "\n" + ex.getMessage(), 0);
                    }
                    if (sdrm != null) {
                        this.setProgress(100);
                        return new ProgressBarModel(SafeDeletePanel.this.resource.getString("delete.succes.file_deleted"), 1);
                    }
                    return new ProgressBarModel(SafeDeletePanel.this.resource.getString("delete.err_msg.delete_failed"), 0);
                }
                return new ProgressBarModel(SafeDeletePanel.this.resource.getString("delete.err_msg.delete_failed"), 0);
            }
        };
        ProgressBarDialog pbd = new ProgressBarDialog(worker);
        pbd.setLocationRelativeTo(this);
        pbd.setVisible(true);
    }

    private void btnBrowseActionPerformed(ActionEvent evt) {
        JFileChooser jfc = new JFileChooser();
        jfc.setAcceptAllFileFilterUsed(false);
        int result = jfc.showOpenDialog(this);
        if (result == 0) {
            this.jtfFilePath.setText(jfc.getSelectedFile().toString());
        }
    }

    private void onItemStateChange(ItemEvent evt) {
        this.jtfNbrRandomAttempts.setEnabled(this.rbtnPRN.isSelected());
    }

    private void initRadioButtons() {
        ButtonGroup bg = new ButtonGroup();
        bg.add(this.rbtnPeterGutmann);
        bg.add(this.rbtnDod3);
        bg.add(this.rbtnDod7);
        bg.add(this.rbtnPRN);
        this.rbtnPeterGutmann.setSelected(true);
    }

    @Override
    public void setSelectedFile(String action, String fileName) {
        this.jtfFilePath.setText(fileName);
    }
}

