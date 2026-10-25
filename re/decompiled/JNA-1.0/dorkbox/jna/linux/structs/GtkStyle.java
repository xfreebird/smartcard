/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByReference
 *  com.sun.jna.Structure$ByValue
 */
package dorkbox.jna.linux.structs;

import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import dorkbox.jna.linux.structs.GObjectStruct;
import dorkbox.jna.linux.structs.GdkColor;
import java.util.Arrays;
import java.util.List;

public class GtkStyle
extends Structure {
    public GObjectStruct parent_instance;
    public GdkColor[] fg = new GdkColor[5];
    public GdkColor[] bg = new GdkColor[5];
    public GdkColor[] light = new GdkColor[5];
    public GdkColor[] dark = new GdkColor[5];
    public GdkColor[] mid = new GdkColor[5];
    public GdkColor[] text = new GdkColor[5];
    public GdkColor[] base = new GdkColor[5];
    public GdkColor[] text_aa = new GdkColor[5];
    public GdkColor black;
    public GdkColor white;
    public Pointer font_desc;
    public int xthickness;
    public int ythickness;
    public Pointer[] background = new Pointer[5];

    public void debug(int gtkState) {
        System.err.println("base " + this.base[gtkState].getColor());
        System.err.println("text " + this.text[gtkState].getColor());
        System.err.println("text_aa " + this.text_aa[gtkState].getColor());
        System.err.println("bg " + this.bg[gtkState].getColor());
        System.err.println("fg " + this.fg[gtkState].getColor());
    }

    protected List<String> getFieldOrder() {
        return Arrays.asList("parent_instance", "fg", "bg", "light", "dark", "mid", "text", "base", "text_aa", "black", "white", "font_desc", "xthickness", "ythickness", "background");
    }

    public class ByValue
    extends GtkStyle
    implements Structure.ByValue {
    }

    public static class ByReference
    extends GtkStyle
    implements Structure.ByReference {
    }
}

