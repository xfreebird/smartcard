/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.formdev.flatlaf.FlatLightLaf
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm;

import com.formdev.flatlaf.FlatLightLaf;
import java.util.Locale;
import javax.swing.SwingUtilities;
import md.cts.moldsign.msccm.MainScreen;
import md.cts.moldsign.msccm.properties.PropertiesLoader;
import md.ghesar.WaitDlg;
import md.gov.stisc.Single;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MoldSignClientCardManagement {
    private static final Logger logger = LoggerFactory.getLogger(MoldSignClientCardManagement.class);

    public static void main(String[] args) {
        logger.info("main start");
        FlatLightLaf.setup();
        String locale = PropertiesLoader.getProperties("Locale").getProperty("Locale", "");
        Locale.setDefault(Locale.forLanguageTag(locale));
        MoldSignClientCardManagement.startUI(args);
        logger.info("main done");
    }

    private static void startUI(String[] args) {
        SwingUtilities.invokeLater(() -> {
            MainScreen ms = new MainScreen(args);
            ms.setLocationRelativeTo(null);
            ms.setVisible(true);
            WaitDlg.display(ms);
        });
    }

    static {
        Single.init();
    }
}

