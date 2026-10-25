/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.ui.popups;

import java.awt.Frame;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.util.concurrent.ExecutionException;
import javax.swing.GroupLayout;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JProgressBar;
import javax.swing.LayoutStyle;
import javax.swing.SwingWorker;
import md.cts.moldsign.clientcardmanager.models.ProgressBarModel;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ProgressBarDialog
extends JDialog
implements PropertyChangeListener {
    private static final Logger logger = LoggerFactory.getLogger(ProgressBarDialog.class);
    private final SwingWorker<ProgressBarModel, String> worker;
    private JLabel lblCurrentOperation;
    private JProgressBar progressBar;

    public ProgressBarDialog(SwingWorker<ProgressBarModel, String> worker) {
        super((Frame)null, true);
        this.setDefaultCloseOperation(2);
        this.initComponents();
        this.pack();
        this.progressBar.setIndeterminate(true);
        this.worker = worker;
    }

    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        if ("progress".equals(evt.getPropertyName())) {
            int progress = (Integer)evt.getNewValue();
            this.progressBar.setIndeterminate(false);
            this.progressBar.setValue(progress);
        }
        if ("currentOperation".equals(evt.getPropertyName())) {
            String message = (String)evt.getNewValue();
            this.lblCurrentOperation.setText(message);
            this.setTitle(message);
        }
        if ("state".equals(evt.getPropertyName())) {
            SwingWorker source = (SwingWorker)evt.getSource();
            if (source.isDone()) {
                try {
                    ProgressBarModel result = (ProgressBarModel)source.get();
                    if (result != null) {
                        JOptionPane.showMessageDialog(this, result.getMessage(), result.getMessage(), result.getMessageType());
                    }
                }
                catch (InterruptedException | ExecutionException ex) {
                    logger.error("", (Throwable)ex);
                }
                source.removePropertyChangeListener(this);
                this.dispose();
            }
            if (source.isCancelled()) {
                JOptionPane.showMessageDialog(this, "Operation canceled", "The operation was canceled", 0);
                source.removePropertyChangeListener(this);
                this.dispose();
            }
        }
    }

    private void initComponents() {
        this.progressBar = new JProgressBar();
        this.lblCurrentOperation = new JLabel();
        this.setIconImage(Resource.getImage((String)"/applogo.png"));
        this.addComponentListener(new ComponentAdapter(){

            @Override
            public void componentShown(ComponentEvent evt) {
                ProgressBarDialog.this.onDialogShow(evt);
            }
        });
        GroupLayout layout = new GroupLayout(this.getContentPane());
        this.getContentPane().setLayout(layout);
        layout.setHorizontalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(layout.createSequentialGroup().addContainerGap().addGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING, false).addComponent(this.progressBar, -1, 268, Short.MAX_VALUE).addComponent(this.lblCurrentOperation, -1, -1, Short.MAX_VALUE)).addContainerGap(-1, Short.MAX_VALUE)));
        layout.setVerticalGroup(layout.createParallelGroup(GroupLayout.Alignment.LEADING).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addContainerGap(25, Short.MAX_VALUE).addComponent(this.lblCurrentOperation).addPreferredGap(LayoutStyle.ComponentPlacement.UNRELATED).addComponent(this.progressBar, -2, -1, -2).addContainerGap()));
    }

    private void onDialogShow(ComponentEvent evt) {
        this.worker.addPropertyChangeListener(this);
        this.worker.execute();
    }
}

