/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  dorkbox.os.OS
 *  dorkbox.os.OS$Linux
 *  org.slf4j.LoggerFactory
 */
package dorkbox.jna.linux;

import com.sun.jna.Pointer;
import dorkbox.jna.JNA;
import dorkbox.jna.linux.Gtk;
import dorkbox.jna.linux.GtkEventDispatch;
import dorkbox.jna.linux.structs.AppIndicatorInstanceStruct;
import dorkbox.os.OS;
import org.slf4j.LoggerFactory;

public class AppIndicator {
    public static final boolean isLoaded;
    public static final int CATEGORY_APPLICATION_STATUS = 0;
    public static final int STATUS_PASSIVE = 0;
    public static final int STATUS_ACTIVE = 1;

    public static String getInstallString(boolean isGtk2) {
        if (isGtk2) {
            if (OS.Linux.INSTANCE.isDebian()) {
                return "libappindicator1";
            }
            if (OS.Linux.INSTANCE.isFedora()) {
                return "libappindicator-gtk";
            }
            if (OS.Linux.INSTANCE.isArch()) {
                return "libappindicator-gtk2";
            }
            return "libappindicator";
        }
        if (OS.Linux.INSTANCE.isDebian()) {
            return "libappindicator3-1";
        }
        if (OS.Linux.INSTANCE.isFedora()) {
            return "libappindicator-gtk3";
        }
        if (OS.Linux.INSTANCE.isArch()) {
            return "libappindicator-gtk3";
        }
        return "libappindicator3";
    }

    public static native AppIndicatorInstanceStruct app_indicator_new(String var0, String var1, int var2);

    public static native void app_indicator_set_title(Pointer var0, String var1);

    public static native void app_indicator_set_status(Pointer var0, int var1);

    public static native void app_indicator_set_menu(Pointer var0, Pointer var1);

    public static native void app_indicator_set_icon(Pointer var0, String var1);

    static {
        boolean shouldLoadAppIndicator;
        boolean _isLoaded = false;
        boolean bl = shouldLoadAppIndicator = !OS.INSTANCE.isWindows() && !OS.INSTANCE.isMacOsX();
        if (!shouldLoadAppIndicator) {
            _isLoaded = true;
        }
        if (!Gtk.isLoaded) {
            shouldLoadAppIndicator = false;
            _isLoaded = true;
        }
        String[] GTK2 = new String[]{"appindicator", "appindicator1", "appindicator-gtk"};
        String[] GTK3 = new String[]{"appindicator3", "appindicator3-1", "appindicator-gtk3", "appindicator-gtk3-1"};
        if (Gtk.isGtk2) {
            for (String libraryName : GTK2) {
                if (_isLoaded) continue;
                try {
                    JNA.register(libraryName, AppIndicator.class);
                    _isLoaded = true;
                    if (!GtkEventDispatch.DEBUG) continue;
                    LoggerFactory.getLogger(AppIndicator.class).debug("Loaded GTK2 library name '{}'.", (Object)libraryName);
                }
                catch (Throwable e) {
                    if (!GtkEventDispatch.DEBUG) continue;
                    LoggerFactory.getLogger(AppIndicator.class).debug("Error loading GTK2 library name '{}'.", (Object)libraryName, (Object)e);
                }
            }
        }
        if (Gtk.isGtk3) {
            for (String libraryName : GTK3) {
                if (_isLoaded) continue;
                try {
                    JNA.register(libraryName, AppIndicator.class);
                    _isLoaded = true;
                    if (!GtkEventDispatch.DEBUG) continue;
                    LoggerFactory.getLogger(AppIndicator.class).debug("Loaded GTK3 library name '{}'.", (Object)libraryName);
                }
                catch (Throwable e) {
                    if (!GtkEventDispatch.DEBUG) continue;
                    LoggerFactory.getLogger(AppIndicator.class).debug("Error loading GTK3 library name '{}'.", (Object)libraryName, (Object)e);
                }
            }
        }
        isLoaded = shouldLoadAppIndicator && _isLoaded;
    }
}

