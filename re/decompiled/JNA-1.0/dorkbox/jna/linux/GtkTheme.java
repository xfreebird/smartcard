/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.ptr.PointerByReference
 *  dorkbox.os.OS
 *  dorkbox.os.OS$DesktopEnv
 *  dorkbox.os.OS$DesktopEnv$Env
 *  dorkbox.os.OS$Linux
 *  org.slf4j.LoggerFactory
 */
package dorkbox.jna.linux;

import com.sun.jna.Pointer;
import com.sun.jna.ptr.PointerByReference;
import dorkbox.jna.KotlinUtils;
import dorkbox.jna.linux.GObject;
import dorkbox.jna.linux.Gtk;
import dorkbox.jna.linux.Gtk2;
import dorkbox.jna.linux.GtkEventDispatch;
import dorkbox.jna.linux.structs.GtkRequisition;
import dorkbox.jna.linux.structs.GtkStyle;
import dorkbox.jna.linux.structs.PangoRectangle;
import dorkbox.os.OS;
import java.awt.Color;
import java.awt.Rectangle;
import java.awt.Toolkit;
import java.io.File;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import org.slf4j.LoggerFactory;

public class GtkTheme {
    public static volatile int TRAY_IMAGE_SIZE_FALLBACK = OS.INSTANCE.getInt(GtkTheme.class.getCanonicalName() + ".TRAY_IMAGE_SIZE_FALLBACK", 24);
    public static volatile int TRAY_MENU_IMAGE_SIZE_FALLBACK = OS.INSTANCE.getInt(GtkTheme.class.getCanonicalName() + ".TRAY_MENU_IMAGE_SIZE_FALLBACK", 16);

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static Rectangle getPixelTextHeight(String text) {
        Pointer menu = null;
        Pointer item = null;
        try {
            menu = Gtk2.Gtk2.gtk_menu_new();
            item = Gtk2.Gtk2.gtk_image_menu_item_new_with_mnemonic(text);
            Gtk2.Gtk2.gtk_container_add(menu, item);
            Gtk2.Gtk2.gtk_widget_realize(menu);
            Gtk2.Gtk2.gtk_widget_realize(item);
            Gtk2.Gtk2.gtk_widget_show_all(menu);
            Pointer textLabel = Gtk2.Gtk2.gtk_bin_get_child(item);
            Pointer pangoLayout = Gtk2.Gtk2.gtk_label_get_layout(textLabel);
            PangoRectangle ink = new PangoRectangle();
            Gtk2.Gtk2.pango_layout_get_pixel_extents(pangoLayout, ink.getPointer(), null);
            ink.read();
            Rectangle rectangle = new Rectangle(ink.width, ink.height);
            Gtk2.Gtk2.gtk_widget_destroy(item);
            Gtk2.Gtk2.gtk_widget_destroy(menu);
            return rectangle;
        }
        catch (Throwable throwable) {
            Gtk2.Gtk2.gtk_widget_destroy(item);
            Gtk2.Gtk2.gtk_widget_destroy(menu);
            throw throwable;
        }
    }

    public static int getMenuEntryImageSize() {
        AtomicReference imageHeight = new AtomicReference();
        GtkEventDispatch.dispatchAndWait(() -> {
            Pointer offscreen = Gtk2.Gtk2.gtk_offscreen_window_new();
            Pointer item = null;
            try {
                item = Gtk2.Gtk2.gtk_image_menu_item_new_from_stock("gtk-paste", null);
                Gtk2.Gtk2.gtk_image_menu_item_set_always_show_image(item, true);
                Gtk2.Gtk2.gtk_container_add(offscreen, item);
                Gtk2.Gtk2.gtk_widget_realize(offscreen);
                Gtk2.Gtk2.gtk_widget_realize(item);
                Gtk2.Gtk2.gtk_widget_show_all(item);
                PointerByReference r = new PointerByReference();
                GObject.g_object_get(item, "image", r.getPointer(), null);
                Pointer imageWidget = r.getValue();
                GtkRequisition gtkRequisition = new GtkRequisition();
                Gtk2.Gtk2.gtk_widget_size_request(imageWidget, gtkRequisition.getPointer());
                gtkRequisition.read();
                imageHeight.set(gtkRequisition.height);
            }
            finally {
                if (item != null) {
                    Gtk2.Gtk2.gtk_widget_destroy(item);
                    Gtk2.Gtk2.gtk_widget_destroy(offscreen);
                }
            }
        });
        int height = (Integer)imageHeight.get();
        if (height > 0) {
            return height;
        }
        LoggerFactory.getLogger(GtkTheme.class).warn("Unable to get tray menu image size. Using fallback: " + TRAY_MENU_IMAGE_SIZE_FALLBACK);
        return TRAY_MENU_IMAGE_SIZE_FALLBACK;
    }

    public static int getIndicatorSize() {
        String envVar;
        int asInteger2;
        Object detectedValue;
        double defaultDPI = 96.0;
        AtomicReference<Double> screenScale = new AtomicReference<Double>();
        AtomicInteger screenDPI = new AtomicInteger();
        screenScale.set(0.0);
        screenDPI.set(0);
        GtkEventDispatch.dispatchAndWait(() -> {
            Pointer window;
            Pointer screen = Gtk2.Gtk2.gdk_screen_get_default();
            if (screen != null) {
                screenDPI.set((int)Gtk2.Gtk2.gdk_screen_get_resolution(screen));
            }
            if (Gtk2.isGtk3 && (window = Gtk2.Gtk2.gdk_get_default_root_window()) != null) {
                double scale = Gtk.Gtk3.gdk_window_get_scale_factor(window);
                screenScale.set(scale);
            }
        });
        if (screenDPI.get() <= 0 && (detectedValue = Toolkit.getDefaultToolkit().getDesktopProperty("gnome.Xft/DPI")) instanceof Integer && (asInteger2 = ((Integer)detectedValue).intValue()) > 1024) {
            int dpi = asInteger2 / 1024;
            screenDPI.set(dpi);
        }
        if (screenDPI.get() < 50) {
            screenDPI.set(96);
        }
        if ((Double)screenScale.get() == 0.0 && (envVar = System.getenv("QT_AUTO_SCREEN_SCALE_FACTOR")) != null) {
            try {
                screenScale.set(Double.parseDouble(envVar));
            }
            catch (Exception asInteger2) {
                // empty catch block
            }
        }
        if ((Double)screenScale.get() == 0.0 && (envVar = System.getenv("QT_SCALE_FACTOR")) != null) {
            try {
                screenScale.set(Double.parseDouble(envVar));
            }
            catch (Exception asInteger2) {
                // empty catch block
            }
        }
        if ((Double)screenScale.get() == 0.0 && (envVar = System.getenv("GDK_SCALE")) != null) {
            try {
                screenScale.set(Double.parseDouble(envVar));
            }
            catch (Exception asInteger2) {
                // empty catch block
            }
        }
        if ((Double)screenScale.get() == 0.0 && (envVar = System.getenv("ELM_SCALE")) != null) {
            try {
                screenScale.set(Double.parseDouble(envVar));
            }
            catch (Exception asInteger2) {
                // empty catch block
            }
        }
        OS.DesktopEnv.Env env = OS.DesktopEnv.INSTANCE.getEnv();
        try {
            String value;
            double scalingFactor;
            String output = KotlinUtils.INSTANCE.execute("gsettings", "get", "org.gnome.desktop.interface", "scaling-factor");
            if (!output.isEmpty() && !output.endsWith("not found") && output.contains("uint32") && (scalingFactor = Double.parseDouble(value = output.substring(output.indexOf("uint") + 7))) >= 1.0) {
                screenScale.set(scalingFactor);
            }
        }
        catch (Throwable output) {
            // empty catch block
        }
        if (OS.DesktopEnv.INSTANCE.isKDE()) {
            File mainFile;
            block38: {
                try {
                    File customSettings = new File("/usr/bin/startkde-custom");
                    if (!customSettings.canRead()) break block38;
                    List<String> lines = KotlinUtils.INSTANCE.readLines(customSettings);
                    for (String line : lines) {
                        String scale;
                        double scalingFactor;
                        String str;
                        int i = line.indexOf(str = "export GDK_SCALE=");
                        if (i <= -1 || !((scalingFactor = Double.parseDouble(scale = line.substring(i + str.length()))) >= 1.0)) continue;
                        screenScale.set(scalingFactor);
                        break;
                    }
                }
                catch (Exception customSettings) {
                    // empty catch block
                }
            }
            if ((Double)screenScale.get() == 0.0 && (mainFile = new File("/usr/share/plasma/plasmoids/org.kde.plasma.private.systemtray/contents/config/main.xml")).canRead()) {
                List<String> lines = KotlinUtils.INSTANCE.readLines(mainFile);
                boolean found = false;
                for (String line : lines) {
                    int index;
                    if (line.contains("<entry name=\"iconSize\" type=\"Int\">")) {
                        found = true;
                    }
                    String str = "<default>";
                    if (!found || (index = line.indexOf(str)) <= -1) continue;
                    String substring = line.substring(index + str.length(), line.indexOf("</default>", index));
                    int imageSize = 0;
                    Integer imageSizeEnum = KotlinUtils.INSTANCE.toInteger(substring);
                    if (imageSizeEnum == null) continue;
                    switch (imageSizeEnum) {
                        case 0: {
                            imageSize = 16;
                            break;
                        }
                        case 1: {
                            imageSize = 22;
                            break;
                        }
                        case 2: {
                            imageSize = 32;
                            break;
                        }
                        case 3: {
                            imageSize = 48;
                            break;
                        }
                        case 4: {
                            imageSize = 64;
                            break;
                        }
                        case 5: {
                            imageSize = 128;
                        }
                    }
                    if (imageSize <= 0) continue;
                    double scaleRatio = (double)screenDPI.get() / 96.0;
                    return (int)(scaleRatio * (double)imageSize);
                }
            }
        }
        if (OS.Linux.INSTANCE.isUbuntu() && OS.DesktopEnv.INSTANCE.isUnity(env)) {
            return 22;
        }
        if (env == OS.DesktopEnv.Env.XFCE) {
            String[] propertiesAsList;
            String properties = OS.DesktopEnv.INSTANCE.queryXfce("xfce4-panel", null);
            for (String prop : propertiesAsList = properties.split(OS.INSTANCE.getLINE_SEPARATOR())) {
                String panelString;
                String panelName;
                if (!prop.startsWith("/plugins/") || !prop.endsWith("/size-max") || !(panelName = OS.DesktopEnv.INSTANCE.queryXfce("xfce4-panel", panelString = prop.substring(0, prop.indexOf("/size-max"))).trim()).equals("systray")) continue;
                String size = OS.DesktopEnv.INSTANCE.queryXfce("xfce4-panel", prop).trim();
                try {
                    return Integer.parseInt(size);
                }
                catch (Exception e) {
                    LoggerFactory.getLogger(GtkTheme.class).error("Unable to get XFCE notification panel size for channel '{}', property '{}'", new Object[]{"xfce4-panel", prop, e});
                }
            }
        }
        AtomicInteger traySize = new AtomicInteger();
        GtkEventDispatch.dispatchAndWait(() -> {
            Pointer screen = Gtk2.Gtk2.gdk_screen_get_default();
            Pointer settings = null;
            if (screen != null) {
                settings = Gtk2.Gtk2.gtk_settings_get_for_screen(screen);
            }
            if (settings != null) {
                PointerByReference pointer = new PointerByReference();
                GObject.g_object_get(settings, "gtk-icon-sizes", pointer.getPointer(), null);
                Pointer value = pointer.getValue();
                if (value != null) {
                    String[] strings;
                    String iconSizes = value.getString(0L);
                    for (String var : strings = new String[]{"panel-menu-bar=", "panel=", "gtk-large-toolbar=", "gtk-small-toolbar="}) {
                        String size;
                        Integer sizeInt;
                        int i = iconSizes.indexOf(var);
                        if (i < 0 || (sizeInt = KotlinUtils.INSTANCE.toInteger(size = iconSizes.substring(i + var.length(), iconSizes.indexOf(",", i)))) == null) continue;
                        traySize.set(sizeInt);
                        return;
                    }
                }
            }
        });
        int i = traySize.get();
        if (i != 0) {
            return i;
        }
        LoggerFactory.getLogger(GtkTheme.class).warn("Unable to get tray image size. Using fallback: " + TRAY_IMAGE_SIZE_FALLBACK);
        return TRAY_IMAGE_SIZE_FALLBACK;
    }

    public static Color getTextColor() {
        AtomicReference<Object> color = new AtomicReference<Object>(null);
        GtkEventDispatch.dispatchAndWait(() -> {
            Pointer menu = null;
            Pointer item = null;
            try {
                menu = Gtk2.Gtk2.gtk_menu_new();
                item = Gtk2.Gtk2.gtk_image_menu_item_new_with_mnemonic("a");
                Gtk2.Gtk2.gtk_container_add(menu, item);
                Gtk2.Gtk2.gtk_widget_realize(menu);
                Gtk2.Gtk2.gtk_widget_realize(item);
                Gtk2.Gtk2.gtk_widget_show_all(menu);
                GtkStyle style = Gtk2.Gtk2.gtk_rc_get_style(item);
                style.read();
                Color c = style.fg[0].getColor();
                color.set(c);
                Gtk2.Gtk2.gtk_widget_destroy(item);
                Gtk2.Gtk2.gtk_widget_destroy(menu);
            }
            catch (Throwable throwable) {
                Gtk2.Gtk2.gtk_widget_destroy(item);
                Gtk2.Gtk2.gtk_widget_destroy(menu);
                throw throwable;
            }
        });
        return color.get();
    }
}

