/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Callback
 *  com.sun.jna.Pointer
 *  com.sun.jna.WString
 *  com.sun.jna.platform.win32.WinDef$HDC
 *  com.sun.jna.platform.win32.WinDef$HICON
 *  com.sun.jna.platform.win32.WinDef$HINSTANCE
 *  com.sun.jna.platform.win32.WinDef$HMENU
 *  com.sun.jna.platform.win32.WinDef$HWND
 *  com.sun.jna.platform.win32.WinDef$LPARAM
 *  com.sun.jna.platform.win32.WinDef$LRESULT
 *  com.sun.jna.platform.win32.WinDef$POINT
 *  com.sun.jna.platform.win32.WinDef$POINT$ByValue
 *  com.sun.jna.platform.win32.WinDef$WPARAM
 *  com.sun.jna.platform.win32.WinNT$HANDLE
 *  com.sun.jna.platform.win32.WinUser$HMONITOR
 */
package dorkbox.jna.windows;

import com.sun.jna.Callback;
import com.sun.jna.Pointer;
import com.sun.jna.WString;
import com.sun.jna.platform.win32.WinDef;
import com.sun.jna.platform.win32.WinNT;
import com.sun.jna.platform.win32.WinUser;
import dorkbox.jna.JNA;
import dorkbox.jna.windows.MSG;
import dorkbox.jna.windows.User32;
import dorkbox.jna.windows.structs.ICONINFO;

public class User32_32
implements User32 {
    @Override
    public native int SetWindowLong(WinDef.HWND var1, int var2, Callback var3);

    @Override
    public native int GetSystemMetrics(int var1);

    @Override
    public native WinDef.LRESULT SendMessage(WinDef.HWND var1, int var2, WinDef.WPARAM var3, WinDef.LPARAM var4);

    @Override
    public native WinDef.HICON CreateIconIndirect(ICONINFO var1);

    @Override
    public native boolean DestroyWindow(WinDef.HWND var1);

    @Override
    public native void PostMessage(WinDef.HWND var1, int var2, WinDef.WPARAM var3, WinDef.LPARAM var4);

    @Override
    public native WinDef.HWND CreateWindowEx(int var1, String var2, String var3, int var4, int var5, int var6, int var7, int var8, WinDef.HWND var9, WinDef.HMENU var10, WinDef.HINSTANCE var11, WinNT.HANDLE var12);

    @Override
    public native WinDef.LRESULT DefWindowProc(WinDef.HWND var1, int var2, WinDef.WPARAM var3, WinDef.LPARAM var4);

    @Override
    public native boolean GetMessage(MSG var1, Pointer var2, int var3, int var4);

    @Override
    public native boolean TranslateMessage(MSG var1);

    @Override
    public native boolean DispatchMessage(MSG var1);

    @Override
    public native int RegisterWindowMessage(WString var1);

    @Override
    public native WinDef.HDC GetDC(WinDef.HWND var1);

    @Override
    public native int ReleaseDC(WinDef.HWND var1, WinDef.HDC var2);

    @Override
    public native boolean GetCursorPos(WinDef.POINT var1);

    @Override
    public native WinUser.HMONITOR MonitorFromPoint(WinDef.POINT.ByValue var1, int var2);

    static {
        JNA.register("user32", User32_32.class);
    }
}

