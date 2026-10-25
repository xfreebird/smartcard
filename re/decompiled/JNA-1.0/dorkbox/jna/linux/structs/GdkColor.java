/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByReference
 *  com.sun.jna.Structure$ByValue
 */
package dorkbox.jna.linux.structs;

import com.sun.jna.Structure;
import java.awt.Color;
import java.util.Arrays;
import java.util.List;

public class GdkColor
extends Structure {
    public int pixel;
    public short red;
    public short green;
    public short blue;

    private static int convert(int inputColor) {
        return inputColor & 0xFF & 0xFF;
    }

    public int red() {
        return GdkColor.convert(this.red);
    }

    public int green() {
        return GdkColor.convert(this.green);
    }

    public int blue() {
        return GdkColor.convert(this.blue);
    }

    public Color getColor() {
        this.read();
        return new Color(this.red(), this.green(), this.blue());
    }

    public String toString() {
        return "[r=" + this.red() + ",g=" + this.green() + ",b=" + this.blue() + "]";
    }

    protected List<String> getFieldOrder() {
        return Arrays.asList("pixel", "red", "green", "blue");
    }

    public static class ByReference
    extends GdkColor
    implements Structure.ByReference {
    }

    public class ByValue
    extends GdkColor
    implements Structure.ByValue {
    }
}

