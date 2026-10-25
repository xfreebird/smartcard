/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Resource
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package svelte;

import cargo.DartBoss;
import cargo.DartCallback;
import cargo.DartCertificate;
import ghesar.DNParser;
import java.awt.Container;
import java.awt.Dialog;
import java.awt.Dimension;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.KeyStroke;
import javax.swing.SwingUtilities;
import md.ghesar.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import svelte.PinDlg;

public final class Coco {
    private static final Logger logger = LoggerFactory.getLogger(Coco.class);
    private static final Object lock = new Object();
    private static volatile int semaphore = 0;
    private JDialog dlg;

    private Coco() {
    }

    public static void displayOneByOne() {
        logger.info("certificate expiration check");
        Map<Long, DartCertificate> dartCertificateList = DartBoss.getDartCertificateList();
        if (dartCertificateList == null) {
            return;
        }
        for (Map.Entry<Long, DartCertificate> entry : dartCertificateList.entrySet()) {
            Long dartCertKey = entry.getKey();
            Coco.display(dartCertKey);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private static void display(Long dartCertKey) {
        Object object = lock;
        synchronized (object) {
            if (semaphore > 0) {
                return;
            }
            ++semaphore;
        }
        try {
            Coco view = new Coco();
            view.init(dartCertKey);
        }
        finally {
            object = lock;
            synchronized (object) {
                --semaphore;
            }
        }
    }

    private void init(Long dartCertKey) {
        logger.info("certificate expiration alert");
        this.dlg = new JDialog(null, "Certificate expiration alert", Dialog.ModalityType.APPLICATION_MODAL);
        this.dlg.setDefaultCloseOperation(2);
        this.dlg.getRootPane().registerKeyboardAction(e -> this.dlg.dispose(), KeyStroke.getKeyStroke(27, 0), 2);
        this.dlg.setIconImage(Resource.getImage((String)"/applogo.png"));
        JButton closeBtn = new JButton("Nu acum, mai t\u00e2rziu.");
        closeBtn.addActionListener(e -> this.dlg.dispose());
        JLabel labelImage1 = new JLabel();
        labelImage1.setIcon(new ImageIcon(Resource.getImage((String)"/time_alarm.png")));
        JLabel labelTitle1 = new JLabel("<html><h2><font color='#ff7800'>Certificatul dumneavoastr\u0103 expir\u0103 \u00een timp apropiat.<br>Este posibil de re\u00eenoit certificatul \u00een token la distan\u021b\u0103.</font></h2></html>", 0);
        JButton confirmBtn1 = new JButton("\u00cencepe\u021bi re\u00eenoirea acum");
        JButton confirmBtn2 = new JButton("Continu\u0103");
        DartCertificate dartCert = DartBoss.getDartCertificate(dartCertKey);
        if (dartCert == null) {
            return;
        }
        String certSubject = dartCert.getCert().getSubjectX500Principal().toString();
        DNParser certSubjectEx = new DNParser(certSubject);
        String personName = certSubjectEx.get("CN");
        String serialNumber = certSubjectEx.get("SERIALNUMBER");
        String organization = certSubjectEx.get("O");
        String phoneNum = certSubjectEx.get("OID.2.5.4.20");
        Date notAfter = dartCert.getCert().getNotAfter();
        SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy HH:mm:ss z");
        String txt1 = "<html><table><tr><td>Persoan\u0103:</td><td>" + personName + "</td></tr><tr><td>IDNP:</td><td>" + serialNumber + "</td></tr><tr><td>Organiza\u021bie:</td><td>" + organization + "</td></tr><tr><td>Num\u0103r telefon:</td><td>" + phoneNum + "</td></tr><tr><td>Data expir\u0103rii:</td><td>" + sdf.format(notAfter) + "</td></tr><table></html>";
        JLabel labelContent1 = new JLabel(txt1);
        Container pane = this.dlg.getContentPane();
        GroupLayout layout = new GroupLayout(pane);
        pane.setLayout(layout);
        layout.setAutoCreateContainerGaps(true);
        layout.setAutoCreateGaps(true);
        Runnable step1 = () -> {
            pane.removeAll();
            layout.setHorizontalGroup(layout.createParallelGroup().addGroup(layout.createSequentialGroup().addComponent(labelImage1).addComponent(labelTitle1)).addGroup(layout.createSequentialGroup().addGap(16).addComponent(labelContent1)).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addComponent(confirmBtn1).addGap(12).addComponent(closeBtn).addGap(4)));
            layout.setVerticalGroup(layout.createSequentialGroup().addGroup(layout.createParallelGroup().addComponent(labelImage1).addComponent(labelTitle1, GroupLayout.Alignment.CENTER)).addGap(12).addComponent(labelContent1).addGap(2, 2, Short.MAX_VALUE).addGroup(layout.createParallelGroup().addComponent(confirmBtn1).addComponent(closeBtn)).addGap(10));
        };
        Runnable step2 = () -> {
            pane.removeAll();
            labelImage1.setIcon(new ImageIcon(Resource.getImage((String)"/personal-information.png")));
            labelTitle1.setText("<html><h2><font color='#ff7800'>Se verific\u0103 datele personale ...</font></h2></html>");
            closeBtn.setText("Renun\u021bare");
            layout.setHorizontalGroup(layout.createParallelGroup().addGroup(layout.createSequentialGroup().addComponent(labelImage1).addComponent(labelTitle1)).addGroup(layout.createSequentialGroup().addGap(16).addComponent(labelContent1)).addGroup(GroupLayout.Alignment.TRAILING, layout.createSequentialGroup().addComponent(confirmBtn2).addGap(8).addComponent(closeBtn).addGap(4)));
            layout.setVerticalGroup(layout.createSequentialGroup().addGroup(layout.createParallelGroup().addComponent(labelImage1).addComponent(labelTitle1, GroupLayout.Alignment.CENTER)).addGap(12).addComponent(labelContent1).addGap(2, 2, Short.MAX_VALUE).addGroup(layout.createParallelGroup().addComponent(confirmBtn2).addComponent(closeBtn)).addGap(10));
        };
        Runnable step3 = () -> labelTitle1.setText("<html><h2><font color='#ff7800'>Datele personale au fost verificate.<br>Pute\u021bi continua re\u00eenoirea certificatului \u00een token.</font></h2></html>");
        Runnable step4 = () -> {
            confirmBtn2.setVisible(false);
            closeBtn.setText("Close");
            labelTitle1.setText("<html><h2><font color='#ff7800'>Nu sau putut verifica datele personale.<br>Pentru re\u00eenoirea certificatului \u00een token este necesar s\u0103 v\u0103 apropia\u021bi la oficiul STISC.</font></h2></html>");
        };
        Runnable step5 = () -> {
            confirmBtn2.setVisible(false);
            closeBtn.setVisible(false);
            labelTitle1.setText("<html><h2><font color='#ff7800'>Se re\u00eenoie\u0219te certificatul,<br>a\u0219tepta\u021bi ...</font></h2></html>");
        };
        Runnable step6 = () -> {
            confirmBtn2.setVisible(false);
            closeBtn.setVisible(true);
            closeBtn.setText("Close");
            labelTitle1.setText("<html><h2><font color='#ff7800'>Certificatul dumneavoastr\u0103 a fost re\u00eenoit cu succes.</font></h2></html>");
            labelImage1.setIcon(new ImageIcon(Resource.getImage((String)"/badge.png")));
        };
        Runnable step7 = () -> {
            confirmBtn2.setVisible(false);
            closeBtn.setVisible(true);
            closeBtn.setText("Close");
            labelTitle1.setText("<html><h2><font color='#ff7800'>Nu sa putut re\u00eenoi certificatul.<br>Pentru rezolvare este necesar s\u0103 contacta\u021bi STISC.</font></h2></html>");
            labelImage1.setIcon(new ImageIcon(Resource.getImage((String)"/error.png")));
        };
        confirmBtn1.addActionListener(e -> {
            step2.run();
            DartBoss.startRenewalPossibility(dartCertKey, code -> {
                logger.info("done RenewalPossibility {}", (Object)code);
                SwingUtilities.invokeLater(() -> {
                    if (code == DartCallback.Code.OK) {
                        step3.run();
                    } else {
                        step4.run();
                    }
                });
            });
        });
        confirmBtn2.addActionListener(e -> PinDlg.display(this.dlg, (success, pin) -> {
            if (success && pin.length > 0) {
                step5.run();
                DartBoss.startGenerate(dartCertKey, pin, code -> {
                    logger.info("done startGenerate {}", (Object)code);
                    SwingUtilities.invokeLater(() -> {
                        if (code == DartCallback.Code.OK) {
                            step6.run();
                        } else {
                            step7.run();
                        }
                    });
                });
            }
        }));
        step1.run();
        this.dlg.setMinimumSize(new Dimension(310, 96));
        this.dlg.setPreferredSize(new Dimension(666, 444));
        this.dlg.pack();
        this.dlg.setLocationRelativeTo(null);
        this.dlg.setVisible(true);
    }
}

