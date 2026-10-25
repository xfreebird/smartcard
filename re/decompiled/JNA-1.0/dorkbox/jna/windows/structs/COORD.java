/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByValue
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Structure;
import java.util.Arrays;
import java.util.List;

public class COORD
extends Structure {
    public short x;
    public short y;

    public ByValue asValue() {
        ByValue copy = new ByValue();
        copy.x = this.x;
        copy.y = this.y;
        return copy;
    }

    protected List<String> getFieldOrder() {
        return Arrays.asList("x", "y");
    }

    public String toString() {
        return this.x + ":" + this.y;
    }

    public static class ByValue
    extends COORD
    implements Structure.ByValue {
    }
}

