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
import javax.swing.ImageIcon;
import md.cts.moldsign.clientcardmanager.ui.main.GnomeTray;
import md.cts.moldsign.clientcardmanager.ui.main.MainScreen;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class MotoCardTray {
    private static final Logger logger = LoggerFactory.getLogger(MotoCardTray.class);
    private static final URL tray_active = GnomeTray.class.getResource("/tray_active32px_XP.png");
    private SystemTray tray = null;
    private TrayIcon trayIcon = null;
    private MainScreen ms = null;

    public void showTray(Long slotGlobalId) {
        if (tray_active == null) {
            return;
        }
        if (!SystemTray.isSupported()) {
            logger.error("SystemTray is not supported");
            return;
        }
        Image img = new ImageIcon(tray_active).getImage();
        this.trayIcon = new TrayIcon(img);
        this.trayIcon.setImageAutoSize(true);
        this.trayIcon.setPopupMenu(this.build(slotGlobalId));
        this.tray = SystemTray.getSystemTray();
        try {
            this.tray.add(this.trayIcon);
        }
        catch (AWTException e) {
            logger.error("Unable to load SystemTray!");
        }
    }

    private PopupMenu build(Long slotGlobalId) {
        PopupMenu popup = new PopupMenu();
        MenuItem aboutItem = new MenuItem("Open Card");
        popup.add(aboutItem);
        aboutItem.addActionListener(e -> {
            this.ms = new MainScreen(slotGlobalId);
        });
        return popup;
    }

    public void closeTray() {
        if (this.ms != null) {
            this.ms.dispose();
            this.ms = null;
        }
        this.tray.remove(this.trayIcon);
    }
}

