/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.platform.win32.WinDef$HBITMAP
 *  com.sun.jna.platform.win32.WinDef$HICON
 *  com.sun.jna.platform.win32.WinNT$HANDLE
 */
package dorkbox.jna.windows;

import com.sun.jna.Pointer;
import com.sun.jna.platform.win32.WinDef;
import com.sun.jna.platform.win32.WinNT;
import dorkbox.jna.windows.GDI32;
import dorkbox.jna.windows.GetLastErrorException;
import dorkbox.jna.windows.HBITMAPWrap;
import dorkbox.jna.windows.User32;
import dorkbox.jna.windows.structs.ICONINFO;

public class HICONWrap
extends WinDef.HICON {
    private static final Object lockObject = new Object();
    private HBITMAPWrap bm;

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    static WinDef.HICON createIconIndirect(WinDef.HBITMAP bm) {
        ICONINFO info = new ICONINFO();
        info.IsIcon = true;
        info.MaskBitmap = bm;
        info.ColorBitmap = bm;
        WinDef.HICON hicon = User32.User32.CreateIconIndirect(info);
        if (hicon == null) {
            Object object = lockObject;
            synchronized (object) {
                hicon = User32.User32.CreateIconIndirect(info);
            }
            if (hicon == null) {
                throw new GetLastErrorException();
            }
        }
        return hicon;
    }

    public HICONWrap() {
    }

    public HICONWrap(Pointer p) {
        super(p);
    }

    public HICONWrap(HBITMAPWrap bm) {
        this.bm = bm;
        this.setPointer(HICONWrap.createIconIndirect(bm).getPointer());
    }

    public void close() {
        this.bm.close();
        if (Pointer.nativeValue((Pointer)this.getPointer()) != 0L) {
            GDI32.DeleteObject((WinNT.HANDLE)this);
            this.setPointer(new Pointer(0L));
        }
    }

    protected void finalize() throws Throwable {
        this.close();
        super.finalize();
    }
}

