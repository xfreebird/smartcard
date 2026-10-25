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
 *  dorkbox.os.OS
 */
package dorkbox.jna.windows;

import com.sun.jna.Callback;
import com.sun.jna.Pointer;
import com.sun.jna.WString;
import com.sun.jna.platform.win32.WinDef;
import com.sun.jna.platform.win32.WinNT;
import com.sun.jna.platform.win32.WinUser;
import dorkbox.jna.windows.MSG;
import dorkbox.jna.windows.User32_32;
import dorkbox.jna.windows.User32_64;
import dorkbox.jna.windows.structs.ICONINFO;
import dorkbox.os.OS;

public interface User32 {
    public static final User32 User32 = OS.INSTANCE.is64bit() ? new User32_64() : new User32_32();
    public static final int GWL_WNDPROC = -4;
    public static final int WM_LBUTTONUP = 514;
    public static final int WM_RBUTTONUP = 517;

    public int SetWindowLong(WinDef.HWND var1, int var2, Callback var3);

    public int GetSystemMetrics(int var1);

    public WinDef.LRESULT SendMessage(WinDef.HWND var1, int var2, WinDef.WPARAM var3, WinDef.LPARAM var4);

    public WinDef.HICON CreateIconIndirect(ICONINFO var1);

    public boolean DestroyWindow(WinDef.HWND var1);

    public void PostMessage(WinDef.HWND var1, int var2, WinDef.WPARAM var3, WinDef.LPARAM var4);

    public WinDef.HWND CreateWindowEx(int var1, String var2, String var3, int var4, int var5, int var6, int var7, int var8, WinDef.HWND var9, WinDef.HMENU var10, WinDef.HINSTANCE var11, WinNT.HANDLE var12);

    public WinDef.LRESULT DefWindowProc(WinDef.HWND var1, int var2, WinDef.WPARAM var3, WinDef.LPARAM var4);

    public boolean GetMessage(MSG var1, Pointer var2, int var3, int var4);

    public boolean TranslateMessage(MSG var1);

    public boolean DispatchMessage(MSG var1);

    public int RegisterWindowMessage(WString var1);

    public WinDef.HDC GetDC(WinDef.HWND var1);

    public int ReleaseDC(WinDef.HWND var1, WinDef.HDC var2);

    public boolean GetCursorPos(WinDef.POINT var1);

    public WinUser.HMONITOR MonitorFromPoint(WinDef.POINT.ByValue var1, int var2);
}

