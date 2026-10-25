/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByValue
 *  com.sun.jna.platform.win32.WinDef$DWORD
 *  com.sun.jna.platform.win32.WinDef$HBITMAP
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Structure;
import com.sun.jna.platform.win32.WinDef;
import java.util.Arrays;
import java.util.List;

public class ICONINFO
extends Structure {
    public boolean IsIcon;
    public WinDef.DWORD xHotspot;
    public WinDef.DWORD yHotspot;
    public WinDef.HBITMAP MaskBitmap;
    public WinDef.HBITMAP ColorBitmap;

    protected List<String> getFieldOrder() {
        return Arrays.asList("IsIcon", "xHotspot", "yHotspot", "MaskBitmap", "ColorBitmap");
    }

    public static class ByValue
    extends ICONINFO
    implements Structure.ByValue {
    }
}

