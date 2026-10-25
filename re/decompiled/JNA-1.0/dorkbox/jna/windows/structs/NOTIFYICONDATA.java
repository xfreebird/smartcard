/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 *  com.sun.jna.platform.win32.WinDef$HICON
 *  com.sun.jna.platform.win32.WinDef$HWND
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Structure;
import com.sun.jna.platform.win32.WinDef;
import java.util.Arrays;
import java.util.List;

public class NOTIFYICONDATA
extends Structure {
    public static final int NIF_MESSAGE = 1;
    public static final int NIF_ICON = 2;
    public static final int NIF_TIP = 4;
    public static final int NIF_STATE = 8;
    public static final int NIF_INFO = 16;
    public static final int NIIF_NONE = 0;
    public static final int NIIF_INFO = 1;
    public static final int NIIF_WARNING = 2;
    public static final int NIIF_ERROR = 3;
    public static final int NIIF_USER = 4;
    public int cbSize;
    public WinDef.HWND hWnd;
    public int uID;
    public int uFlags;
    public int uCallbackMessage;
    public WinDef.HICON hIcon;
    public char[] szTip = new char[128];
    public int dwState;
    public int dwStateMask;
    public char[] szInfo = new char[256];
    public int uTimeoutOrVersion;
    public char[] szInfoTitle = new char[64];
    public int dwInfoFlags;

    public NOTIFYICONDATA() {
        this.cbSize = this.size();
    }

    public void setTooltip(String s) {
        this.uFlags |= 4;
        System.arraycopy(s.toCharArray(), 0, this.szTip, 0, Math.min(s.length(), this.szTip.length));
        this.szTip[s.length()] = '\u0000';
    }

    public void setBalloon(String title, String message, int millis, int niif) {
        this.uFlags |= 0x10;
        System.arraycopy(message.toCharArray(), 0, this.szInfo, 0, Math.min(message.length(), this.szInfo.length));
        this.szInfo[message.length()] = '\u0000';
        this.uTimeoutOrVersion = millis;
        System.arraycopy(title.toCharArray(), 0, this.szInfoTitle, 0, Math.min(title.length(), this.szInfoTitle.length));
        this.szInfoTitle[title.length()] = '\u0000';
        this.dwInfoFlags = niif;
    }

    public void setIcon(WinDef.HICON hIcon) {
        this.uFlags |= 2;
        this.hIcon = hIcon;
    }

    public void setCallback(int callback) {
        this.uFlags |= 1;
        this.uCallbackMessage = callback;
    }

    protected List<String> getFieldOrder() {
        return Arrays.asList("cbSize", "hWnd", "uID", "uFlags", "uCallbackMessage", "hIcon", "szTip", "dwState", "dwStateMask", "szInfo", "uTimeoutOrVersion", "szInfoTitle", "dwInfoFlags");
    }
}

