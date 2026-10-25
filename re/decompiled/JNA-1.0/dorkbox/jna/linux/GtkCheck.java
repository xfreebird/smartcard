/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 */
package dorkbox.jna.linux;

import dorkbox.jna.rendering.RenderProvider;
import dorkbox.os.OS;
import java.lang.reflect.Field;

public class GtkCheck {
    public static volatile boolean isGtk2 = false;
    public static volatile boolean isGtk3 = false;
    public static volatile boolean isGtkLoaded = false;
    public static volatile int MAJOR = 0;
    public static volatile int MINOR = 0;
    public static volatile int MICRO = 0;

    public static boolean gtkIsGreaterOrEqual(int major, int minor, int micro) {
        if (MAJOR > major) {
            return true;
        }
        if (MAJOR < major) {
            return false;
        }
        if (MINOR > minor) {
            return true;
        }
        if (MINOR < minor) {
            return false;
        }
        if (MICRO > micro) {
            return true;
        }
        return MICRO >= micro;
    }

    public static int getLoadedGtkVersion() {
        if (isGtkLoaded) {
            if (isGtk3) {
                return 3;
            }
            return 2;
        }
        int gtkVersion = RenderProvider.getGtkVersion();
        if (gtkVersion > 0) {
            return gtkVersion;
        }
        if (OS.INSTANCE.getJavaVersion() <= 8) {
            try {
                Class<?> unixTkClazz;
                Class<?> toolkitClass = Class.forName("java.awt.Toolkit");
                Field kitField = toolkitClass.getDeclaredField("toolkit");
                kitField.setAccessible(true);
                Object toolkit = kitField.get(null);
                if (toolkit != null && (unixTkClazz = Class.forName("sun.awt.UNIXToolkit")).isAssignableFrom(toolkit.getClass())) {
                    Field field = unixTkClazz.getDeclaredField("nativeGTKLoaded");
                    field.setAccessible(true);
                    Boolean o = (Boolean)field.get(toolkit);
                    if (o != null && o.booleanValue()) {
                        return 2;
                    }
                }
            }
            catch (Throwable throwable) {
                // empty catch block
            }
        }
        return 0;
    }
}

