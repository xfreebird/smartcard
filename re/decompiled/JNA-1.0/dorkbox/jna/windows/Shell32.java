/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.jna.windows;

import dorkbox.jna.JNA;
import dorkbox.jna.windows.structs.NOTIFYICONDATA;

public class Shell32 {
    public static final int NIM_ADD = 0;
    public static final int NIM_MODIFY = 1;
    public static final int NIM_DELETE = 2;

    public static native boolean Shell_NotifyIcon(int var0, NOTIFYICONDATA var1);

    static {
        JNA.register("shell32", Shell32.class);
    }
}

