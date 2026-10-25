/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.Structure
 */
package dorkbox.jna.windows;

import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import dorkbox.jna.windows.Parameter;
import java.util.Arrays;
import java.util.List;

public class MSG
extends Structure {
    public Pointer hWnd;
    public int message;
    public Parameter wParam;
    public Parameter lParam;
    public int time;
    public int x;
    public int y;

    protected List<String> getFieldOrder() {
        return Arrays.asList("hWnd", "message", "wParam", "lParam", "time", "x", "y");
    }
}

