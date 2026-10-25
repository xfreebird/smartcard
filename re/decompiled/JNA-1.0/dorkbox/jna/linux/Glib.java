/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Callback
 *  com.sun.jna.NativeLibrary
 *  com.sun.jna.Pointer
 *  org.slf4j.LoggerFactory
 */
package dorkbox.jna.linux;

import com.sun.jna.Callback;
import com.sun.jna.NativeLibrary;
import com.sun.jna.Pointer;
import dorkbox.jna.JNA;
import org.slf4j.LoggerFactory;

public class Glib {
    public static final GLogFunc nullLogFunc;

    public static native int g_log_set_handler(String var0, int var1, GLogFunc var2, Pointer var3);

    public static native void g_log_default_handler(String var0, int var1, String var2, Pointer var3);

    public static native GLogFunc g_log_set_default_handler(GLogFunc var0, Pointer var1);

    public static native void g_log_remove_handler(String var0, int var1);

    static {
        try {
            NativeLibrary library = JNA.register("glib-2.0", Glib.class);
            if (library == null) {
                LoggerFactory.getLogger(Glib.class).error("Error loading Glib library, it failed to load.");
            }
        }
        catch (Throwable e) {
            LoggerFactory.getLogger(Glib.class).error("Error loading Glib library, it failed to load {}", (Object)e.getMessage());
        }
        nullLogFunc = new GLogFunc(){

            @Override
            public void callback(String log_domain, int log_level, String message, Pointer data) {
            }
        };
    }

    public static interface GLogFunc
    extends Callback {
        public void callback(String var1, int var2, String var3, Pointer var4);
    }

    public static interface GLogLevelFlags {
        public static final int RECURSION = 1;
        public static final int FATAL = 2;
        public static final int ERROR = 4;
        public static final int CRITICAL = 8;
        public static final int WARNING = 16;
        public static final int MESSAGE = 32;
        public static final int INFO = 64;
        public static final int DEBUG = 128;
        public static final int MASK = -4;
    }
}

