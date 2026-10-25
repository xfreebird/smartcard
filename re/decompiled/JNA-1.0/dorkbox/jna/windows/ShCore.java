/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Function
 *  com.sun.jna.NativeLibrary
 *  com.sun.jna.platform.win32.WinNT$HRESULT
 *  com.sun.jna.platform.win32.WinUser$HMONITOR
 *  com.sun.jna.ptr.IntByReference
 *  dorkbox.os.OS$Windows
 */
package dorkbox.jna.windows;

import com.sun.jna.Function;
import com.sun.jna.NativeLibrary;
import com.sun.jna.platform.win32.WinNT;
import com.sun.jna.platform.win32.WinUser;
import com.sun.jna.ptr.IntByReference;
import dorkbox.jna.JNA;
import dorkbox.os.OS;

public class ShCore {
    private static Function GetDpiForMonitor = null;

    public static WinNT.HRESULT GetDpiForMonitor(WinUser.HMONITOR hMonitor, int dpiType, IntByReference dpiX, IntByReference dpiY) {
        if (GetDpiForMonitor != null) {
            return (WinNT.HRESULT)GetDpiForMonitor.invoke(WinNT.HRESULT.class, new Object[]{hMonitor.getPointer(), dpiType, dpiX, dpiY});
        }
        return null;
    }

    static {
        if (OS.Windows.INSTANCE.isWindows8_1_plus()) {
            NativeLibrary library = JNA.register("shcore", ShCore.class);
            GetDpiForMonitor = library.getFunction("GetDpiForMonitor");
        }
    }
}

