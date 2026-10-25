/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.ui.main;

import java.awt.AWTException;
import java.awt.Image;
import java.awt.MenuItem;
import java.awt.PopupMenu;
import java.awt.SystemTray;
import java.awt.TrayIcon;
import java.net.URL;
import java.util.ResourceBundle;
import javax.swing.ImageIcon;
import md.cts.moldsign.clientcardmanager.start.ClientCardManager;
import md.cts.moldsign.clientcardmanager.ui.configuration.popups.ConfigurationDialogMain;
import md.cts.moldsign.clientcardmanager.ui.popups.AboutPageDialog;
import md.cts.moldsign.clientcardmanager.ui.popups.DiagnosticDialog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class MotoTray {
    private static final Logger logger = LoggerFactory.getLogger(MotoTray.class);
    private static final ResourceBundle resource = ResourceBundle.getBundle("translations");
    private static final URL tray_inactive = MotoTray.class.getResource("/tray_inactive32px_XP.png");
    private static SystemTray tray = null;
    private static TrayIcon trayIcon = null;

    public static void showSystemTray() {
        if (tray_inactive == null) {
            return;
        }
        if (!SystemTray.isSupported()) {
            logger.error("SystemTray is not supported");
            return;
        }
        Image img = new ImageIcon(tray_inactive).getImage();
        trayIcon = new TrayIcon(img);
        trayIcon.setImageAutoSize(true);
        trayIcon.setPopupMenu(MotoTray.build());
        tray = SystemTray.getSystemTray();
        try {
            tray.add(trayIcon);
        }
        catch (AWTException e) {
            logger.error("Unable to load SystemTray!");
        }
    }

    private static PopupMenu build() {
        PopupMenu popup = new PopupMenu();
        MenuItem aboutItem = new MenuItem(resource.getString("splashscreen.menu_item.help.about"));
        MenuItem diagnosticItem = new MenuItem(resource.getString("menu.menu_item.diagnostic"));
        MenuItem configurationItem = new MenuItem(resource.getString("splashscreen.menuitem.options"));
        MenuItem exitItem = new MenuItem("Exit");
        popup.add(aboutItem);
        popup.add(diagnosticItem);
        popup.add(configurationItem);
        popup.add(exitItem);
        aboutItem.addActionListener(e -> {
            AboutPageDialog aboutPanel = new AboutPageDialog();
            aboutPanel.setLocationRelativeTo(null);
            aboutPanel.setVisible(true);
        });
        diagnosticItem.addActionListener(e -> {
            DiagnosticDialog dd = new DiagnosticDialog();
            dd.fillInformation();
            dd.setLocationRelativeTo(null);
            dd.setVisible(true);
        });
        configurationItem.addActionListener(e -> {
            ConfigurationDialogMain cdm = new ConfigurationDialogMain();
            cdm.initTabs();
            cdm.setLocationRelativeTo(null);
            cdm.setVisible(true);
        });
        exitItem.addActionListener(e -> {
            logger.info("Exit");
            tray.remove(trayIcon);
            ClientCardManager.stopApplication();
            try {
                Thread.sleep(200L);
            }
            catch (InterruptedException ex) {
                logger.error("final sleep", (Throwable)ex);
            }
            System.exit(0);
        });
        return popup;
    }
}

