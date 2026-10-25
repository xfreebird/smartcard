/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.systemTray.Entry
 *  dorkbox.systemTray.Menu
 *  dorkbox.systemTray.MenuItem
 *  dorkbox.systemTray.SystemTray
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.clientcardmanager.ui.main;

import dorkbox.systemTray.Entry;
import dorkbox.systemTray.Menu;
import dorkbox.systemTray.MenuItem;
import dorkbox.systemTray.SystemTray;
import java.net.URL;
import md.cts.moldsign.clientcardmanager.ui.main.GnomeTray;
import md.cts.moldsign.clientcardmanager.ui.main.MainScreen;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class GnomeCardTray {
    private static final Logger logger = LoggerFactory.getLogger(GnomeCardTray.class);
    private static final URL tray_active = GnomeTray.class.getResource("/tray_active32px_XP.png");
    private SystemTray systemTray = null;
    private MainScreen ms = null;

    public void showTray(Long slotGlobalId) {
        if (tray_active == null) {
            return;
        }
        if (this.systemTray != null) {
            return;
        }
        String uniqueName = "MoldTrayCard-" + slotGlobalId;
        this.systemTray = SystemTray.get((String)uniqueName);
        if (this.systemTray == null) {
            logger.error("Unable to load SystemTray!");
            return;
        }
        this.systemTray.setImage(tray_active);
        Menu mainMenu = this.systemTray.getMenu();
        mainMenu.add((Entry)new MenuItem("Open Card", e -> {
            this.ms = new MainScreen(slotGlobalId);
        }));
    }

    public void closeTray() {
        if (this.ms != null) {
            this.ms.dispose();
            this.ms = null;
        }
        if (this.systemTray != null) {
            this.systemTray.shutdown();
            this.systemTray = null;
        }
    }
}

