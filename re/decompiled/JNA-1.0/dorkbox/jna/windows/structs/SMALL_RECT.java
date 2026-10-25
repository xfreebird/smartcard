/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByReference
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Structure;
import java.util.Arrays;
import java.util.List;

public class SMALL_RECT
extends Structure {
    public short left;
    public short top;
    public short right;
    public short bottom;

    public short width() {
        return (short)(this.right - this.left);
    }

    public short height() {
        return (short)(this.bottom - this.top);
    }

    protected List<String> getFieldOrder() {
        return Arrays.asList("left", "top", "right", "bottom");
    }

    public String toString() {
        return "LTRB: " + this.left + "," + this.top + "," + this.right + "," + this.bottom;
    }

    public static class ByReference
    extends SMALL_RECT
    implements Structure.ByReference {
    }
}

