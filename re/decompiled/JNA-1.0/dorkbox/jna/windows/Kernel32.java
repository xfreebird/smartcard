/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.platform.win32.Kernel32Util
 *  com.sun.jna.platform.win32.WinNT$HANDLE
 *  com.sun.jna.ptr.IntByReference
 */
package dorkbox.jna.windows;

import com.sun.jna.platform.win32.Kernel32Util;
import com.sun.jna.platform.win32.WinNT;
import com.sun.jna.ptr.IntByReference;
import dorkbox.jna.JNA;
import dorkbox.jna.windows.structs.CONSOLE_SCREEN_BUFFER_INFO;
import dorkbox.jna.windows.structs.COORD;
import dorkbox.jna.windows.structs.INPUT_RECORD;
import dorkbox.jna.windows.structs.SMALL_RECT;

public class Kernel32 {
    public static final short FOREGROUND_BLACK = 0;
    public static final short FOREGROUND_BLUE = 1;
    public static final short FOREGROUND_GREEN = 2;
    public static final short FOREGROUND_CYAN = 3;
    public static final short FOREGROUND_RED = 4;
    public static final short FOREGROUND_MAGENTA = 5;
    public static final short FOREGROUND_YELLOW = 6;
    public static final short FOREGROUND_GREY = 7;
    public static final short FOREGROUND_INTENSITY = 8;
    public static final short BACKGROUND_BLACK = 0;
    public static final short BACKGROUND_BLUE = 16;
    public static final short BACKGROUND_GREEN = 32;
    public static final short BACKGROUND_CYAN = 48;
    public static final short BACKGROUND_RED = 64;
    public static final short BACKGROUND_MAGENTA = 80;
    public static final short BACKGROUND_YELLOW = 96;
    public static final short BACKGROUND_GREY = 112;
    public static final short BACKGROUND_INTENSITY = 128;
    public static final short COMMON_LVB_LEADING_BYTE = 256;
    public static final short COMMON_LVB_TRAILING_BYTE = 512;
    public static final short COMMON_LVB_GRID_HORIZONTAL = 1024;
    public static final short COMMON_LVB_GRID_LVERTICAL = 2048;
    public static final short COMMON_LVB_GRID_RVERTICAL = 4096;
    public static final short COMMON_LVB_REVERSE_VIDEO = 16384;
    public static final short COMMON_LVB_UNDERSCORE = Short.MIN_VALUE;
    public static final int FORMAT_MESSAGE_FROM_SYSTEM = 4096;

    public static void ASSERT(int returnValue, String message) {
        assert (returnValue != 0) : message + " : " + Kernel32Util.getLastErrorMessage();
    }

    public static native WinNT.HANDLE GetStdHandle(int var0);

    public static native int CloseHandle(WinNT.HANDLE var0);

    public static native int SetConsoleTextAttribute(WinNT.HANDLE var0, short var1);

    public static native int GetConsoleScreenBufferInfo(WinNT.HANDLE var0, CONSOLE_SCREEN_BUFFER_INFO var1);

    public static native int SetConsoleCursorPosition(WinNT.HANDLE var0, COORD.ByValue var1);

    public static native int ScrollConsoleScreenBuffer(WinNT.HANDLE var0, SMALL_RECT.ByReference var1, SMALL_RECT.ByReference var2, COORD.ByValue var3, IntByReference var4);

    public static native int FillConsoleOutputAttribute(WinNT.HANDLE var0, short var1, int var2, COORD.ByValue var3, IntByReference var4);

    public static native int FillConsoleOutputCharacter(WinNT.HANDLE var0, char var1, int var2, COORD.ByValue var3, IntByReference var4);

    public static native int GetConsoleMode(WinNT.HANDLE var0, IntByReference var1);

    public static native int SetConsoleMode(WinNT.HANDLE var0, int var1);

    public static native int ReadConsoleInput(WinNT.HANDLE var0, INPUT_RECORD.ByReference var1, int var2, IntByReference var3);

    static {
        JNA.register("kernel32", Kernel32.class);
    }
}

