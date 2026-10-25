/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.platform.win32.WinDef$HBITMAP
 *  com.sun.jna.platform.win32.WinDef$HDC
 *  com.sun.jna.platform.win32.WinGDI$BITMAPINFO
 *  com.sun.jna.platform.win32.WinNT$HANDLE
 *  com.sun.jna.ptr.PointerByReference
 */
package dorkbox.jna.windows;

import com.sun.jna.Pointer;
import com.sun.jna.platform.win32.WinDef;
import com.sun.jna.platform.win32.WinGDI;
import com.sun.jna.platform.win32.WinNT;
import com.sun.jna.ptr.PointerByReference;
import dorkbox.jna.JNA;

public class GDI32 {
    public static native WinDef.HDC CreateCompatibleDC(WinDef.HDC var0);

    public static native boolean DeleteDC(WinDef.HDC var0);

    public static native boolean DeleteObject(WinNT.HANDLE var0);

    public static native WinDef.HBITMAP CreateDIBSection(WinDef.HDC var0, WinGDI.BITMAPINFO var1, int var2, PointerByReference var3, Pointer var4, int var5);

    static {
        JNA.register("GDI32", GDI32.class);
    }
}

