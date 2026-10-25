/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 */
package dorkbox.jna.linux.structs;

import com.sun.jna.Structure;
import java.util.Arrays;
import java.util.List;

public class PangoRectangle
extends Structure {
    public int x;
    public int y;
    public int width;
    public int height;

    protected List<String> getFieldOrder() {
        return Arrays.asList("x", "y", "width", "height");
    }
}

