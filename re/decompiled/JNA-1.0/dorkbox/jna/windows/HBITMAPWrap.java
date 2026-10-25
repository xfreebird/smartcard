/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Memory
 *  com.sun.jna.Pointer
 *  com.sun.jna.platform.win32.Kernel32Util
 *  com.sun.jna.platform.win32.WinDef$HBITMAP
 *  com.sun.jna.platform.win32.WinDef$HDC
 *  com.sun.jna.platform.win32.WinGDI$BITMAPINFO
 *  com.sun.jna.platform.win32.WinNT$HANDLE
 *  com.sun.jna.ptr.PointerByReference
 *  org.slf4j.LoggerFactory
 */
package dorkbox.jna.windows;

import com.sun.jna.Memory;
import com.sun.jna.Pointer;
import com.sun.jna.platform.win32.Kernel32Util;
import com.sun.jna.platform.win32.WinDef;
import com.sun.jna.platform.win32.WinGDI;
import com.sun.jna.platform.win32.WinNT;
import com.sun.jna.ptr.PointerByReference;
import dorkbox.jna.windows.GDI32;
import dorkbox.jna.windows.User32;
import java.awt.AlphaComposite;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.awt.image.Raster;
import org.slf4j.LoggerFactory;

public class HBITMAPWrap
extends WinDef.HBITMAP {
    private static final Object lockObject = new Object();
    private WinDef.HBITMAP bitmap;
    BufferedImage img;

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private static WinDef.HBITMAP createBitmap(BufferedImage image) {
        int w = image.getWidth(null);
        int h = image.getHeight(null);
        Object object = lockObject;
        synchronized (object) {
            WinDef.HBITMAP hBITMAP;
            WinDef.HDC screenDC = User32.User32.GetDC(null);
            WinDef.HDC memDC = GDI32.CreateCompatibleDC(screenDC);
            WinDef.HBITMAP hBitmap = null;
            try {
                BufferedImage buf = new BufferedImage(w, h, 3);
                Graphics2D g = (Graphics2D)buf.getGraphics();
                g.setComposite(AlphaComposite.getInstance(3));
                g.drawImage(image, 0, 0, w, h, null);
                WinGDI.BITMAPINFO bmi = new WinGDI.BITMAPINFO();
                bmi.bmiHeader.biWidth = w;
                bmi.bmiHeader.biHeight = h;
                bmi.bmiHeader.biPlanes = 1;
                bmi.bmiHeader.biBitCount = (short)32;
                bmi.bmiHeader.biCompression = 0;
                bmi.bmiHeader.biSizeImage = w * h * 4;
                Memory memory = new Memory((long)(w * h * 32 * 4));
                PointerByReference pointerRef = new PointerByReference((Pointer)memory);
                hBitmap = GDI32.CreateDIBSection(memDC, bmi, 0, pointerRef, null, 0);
                Pointer pointerToBits = pointerRef.getValue();
                if (pointerToBits == null) {
                    LoggerFactory.getLogger(HBITMAPWrap.class).error("The image was invalid", (Object)Kernel32Util.getLastErrorMessage());
                } else {
                    Raster raster = buf.getData();
                    int[] pixel = new int[4];
                    int[] bits = new int[w * h];
                    for (int y = 0; y < h; ++y) {
                        for (int x = 0; x < w; ++x) {
                            raster.getPixel(x, h - y - 1, pixel);
                            int red = (pixel[2] & 0xFF) << 0;
                            int green = (pixel[1] & 0xFF) << 8;
                            int blue = (pixel[0] & 0xFF) << 16;
                            int alpha = (pixel[3] & 0xFF) << 24;
                            bits[x + y * w] = alpha | red | green | blue;
                        }
                    }
                    pointerToBits.write(0L, bits, 0, bits.length);
                }
                hBITMAP = hBitmap;
                User32.User32.ReleaseDC(null, screenDC);
            }
            catch (Throwable throwable) {
                User32.User32.ReleaseDC(null, screenDC);
                GDI32.DeleteDC(memDC);
                throw throwable;
            }
            GDI32.DeleteDC(memDC);
            return hBITMAP;
        }
    }

    public HBITMAPWrap(BufferedImage img) {
        this.bitmap = HBITMAPWrap.createBitmap(img);
        this.setPointer(this.bitmap.getPointer());
        this.img = img;
    }

    protected void finalize() throws Throwable {
        this.close();
        super.finalize();
    }

    public void close() {
        if (Pointer.nativeValue((Pointer)this.getPointer()) != 0L) {
            GDI32.DeleteObject((WinNT.HANDLE)this);
            this.setPointer(new Pointer(0L));
            this.bitmap = null;
        }
    }

    public BufferedImage getImage() {
        return this.img;
    }
}

