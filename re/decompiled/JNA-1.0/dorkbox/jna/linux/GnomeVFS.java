/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.NativeLibrary
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.linux;

import com.sun.jna.NativeLibrary;
import com.sun.jna.Pointer;
import dorkbox.jna.JNA;

public class GnomeVFS {
    public static final boolean isInited;

    public static native void gnome_vfs_init();

    public static native int gnome_vfs_url_show_with_env(String var0, Pointer var1);

    static {
        boolean init = false;
        try {
            NativeLibrary library = JNA.register("libgnomevfs-2", GnomeVFS.class);
            if (library == null) {
                library = JNA.register("libgnomevfs", GnomeVFS.class);
            }
            if (library == null) {
                library = JNA.register("libgnomevfs-3", GnomeVFS.class);
            }
            if (library != null) {
                GnomeVFS.gnome_vfs_init();
                init = true;
            }
        }
        catch (Throwable throwable) {
            // empty catch block
        }
        isInited = init;
    }
}

