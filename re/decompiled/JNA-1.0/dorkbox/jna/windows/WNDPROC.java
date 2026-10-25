/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.platform.win32.WinDef$HWND
 *  com.sun.jna.platform.win32.WinDef$LPARAM
 *  com.sun.jna.platform.win32.WinDef$LRESULT
 *  com.sun.jna.platform.win32.WinDef$WPARAM
 *  com.sun.jna.win32.StdCallLibrary$StdCallCallback
 */
package dorkbox.jna.windows;

import com.sun.jna.platform.win32.WinDef;
import com.sun.jna.win32.StdCallLibrary;

public interface WNDPROC
extends StdCallLibrary.StdCallCallback {
    public WinDef.LRESULT callback(WinDef.HWND var1, int var2, WinDef.WPARAM var3, WinDef.LPARAM var4);
}

