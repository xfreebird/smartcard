/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.systemTray.Entry
 *  dorkbox.systemTray.Menu
 *  dorkbox.systemTray.MenuItem
 *  dorkbox.systemTray.Separator
 *  dorkbox.systemTray.SystemTray
 *  dorkbox.systemTray.SystemTray$TrayType
 *  md.gov.stisc.Single
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.ui.main;

import dorkbox.systemTray.Entry;
import dorkbox.systemTray.Menu;
import dorkbox.systemTray.MenuItem;
import dorkbox.systemTray.Separator;
import dorkbox.systemTray.SystemTray;
import java.net.URL;
import java.util.ResourceBundle;
import md.cts.moldsign.clientcardmanager.start.ClientCardManager;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.ConfigurationDialogMain;
import md.cts.moldsign.clientcardmanager.ui.popups.AboutPageDialog;
import md.cts.moldsign.clientcardmanager.ui.popups.DiagnosticDialog;
import md.gov.stisc.Single;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class GnomeTray {
    private static final Logger logger = LoggerFactory.getLogger(GnomeTray.class);
    private static final ResourceBundle resource = ResourceBundle.getBundle("translations");
    private static final URL tray_inactive = GnomeTray.class.getResource("/tray_inactive32px_XP.png");

    public static void showSystemTray() {
        SystemTray systemTray;
        if (tray_inactive == null) {
            return;
        }
        SystemTray.DEBUG = true;
        if (Single.isMac) {
            SystemTray.FORCE_TRAY_TYPE = SystemTray.TrayType.Swing;
        }
        if ((systemTray = SystemTray.get((String)"MoldTray")) == null) {
            logger.error("Unable to load SystemTray!");
            return;
        }
        systemTray.setImage(tray_inactive);
        Menu mainMenu = systemTray.getMenu();
        mainMenu.add((Entry)new MenuItem(resource.getString("splashscreen.menu_item.help.about"), e -> {
            AboutPageDialog aboutPanel = new AboutPageDialog();
            aboutPanel.setLocationRelativeTo(null);
            aboutPanel.setVisible(true);
        }));
        mainMenu.add((Entry)new MenuItem(resource.getString("menu.menu_item.diagnostic"), e -> {
            DiagnosticDialog dd = new DiagnosticDialog();
            dd.fillInformation();
            dd.setLocationRelativeTo(null);
            dd.setVisible(true);
        }));
        mainMenu.add((Entry)new MenuItem(resource.getString("splashscreen.menuitem.options"), e -> {
            ConfigurationDialogMain cdm = new ConfigurationDialogMain();
            cdm.initTabs();
            cdm.setLocationRelativeTo(null);
            cdm.setVisible(true);
        }));
        mainMenu.add((Entry)new Separator());
        mainMenu.add((Entry)new MenuItem("Exit", e -> {
            logger.info("Exit");
            systemTray.shutdown();
            ClientCardManager.stopApplication();
            try {
                Thread.sleep(200L);
            }
            catch (InterruptedException ex) {
                logger.error("final sleep", (Throwable)ex);
            }
            System.exit(0);
        }));
    }
}

