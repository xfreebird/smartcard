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

public class GObject {
    public static native void g_object_ref(Pointer var0);

    public static native void g_object_unref(Pointer var0);

    public static native void g_object_force_floating(Pointer var0);

    public static native void g_object_ref_sink(Pointer var0);

    public static native long g_signal_connect_object(Pointer var0, String var1, Callback var2, Pointer var3, int var4);

    public static native void g_signal_handler_block(Pointer var0, long var1);

    public static native void g_signal_handler_unblock(Pointer var0, long var1);

    public static native void g_object_get(Pointer var0, String var1, Pointer var2, Pointer var3);

    public static native void g_value_init(Pointer var0, double var1);

    public static native void g_value_unset(Pointer var0);

    public static native String g_value_get_string(Pointer var0);

    public static native int g_value_get_int(Pointer var0);

    public static native Pointer g_type_class_ref(Pointer var0);

    public static native void g_type_class_unref(Pointer var0);

    static {
        try {
            NativeLibrary library = JNA.register("gobject-2.0", GObject.class);
            if (library == null) {
                LoggerFactory.getLogger(GObject.class).error("Error loading GObject library, it failed to load.");
            }
        }
        catch (Throwable e) {
            LoggerFactory.getLogger(GObject.class).error("Error loading GObject library, it failed to load {}", (Object)e.getMessage());
        }
    }
}

