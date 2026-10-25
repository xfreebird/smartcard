/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Native
 *  com.sun.jna.ptr.IntByReference
 */
package dorkbox.jna.linux;

import com.sun.jna.Native;
import com.sun.jna.ptr.IntByReference;
import dorkbox.jna.linux.structs.Termios;
import java.nio.ByteBuffer;

public class CLibraryPosix {
    public static final int TIOCGWINSZ;

    public static native int isatty(int var0);

    public static native int read(int var0, IntByReference var1, int var2);

    public static native int ioctl(int var0, int var1, ByteBuffer var2);

    public static native int tcgetattr(int var0, Termios var1);

    public static native int tcsetattr(int var0, int var1, Termios var2);

    static {
        Native.register((String)"c");
        TIOCGWINSZ = System.getProperty("os.name").equalsIgnoreCase("linux") ? 21523 : 1074295912;
    }
}

