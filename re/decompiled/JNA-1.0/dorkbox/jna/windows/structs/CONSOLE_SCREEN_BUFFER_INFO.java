/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Structure;
import dorkbox.jna.windows.structs.COORD;
import dorkbox.jna.windows.structs.SMALL_RECT;
import java.util.Arrays;
import java.util.List;

public class CONSOLE_SCREEN_BUFFER_INFO
extends Structure {
    public COORD size = new COORD();
    public COORD cursorPosition = new COORD();
    public short attributes = 0;
    public SMALL_RECT window = new SMALL_RECT();
    public COORD maximumWindowSize = new COORD();

    protected List<String> getFieldOrder() {
        return Arrays.asList("size", "cursorPosition", "attributes", "window", "maximumWindowSize");
    }

    public String toString() {
        return "Size: " + (Object)((Object)this.size) + " CursorPos: " + (Object)((Object)this.cursorPosition) + " Attribs: " + this.attributes + " Window: " + (Object)((Object)this.window) + " MaxWindowSize: " + (Object)((Object)this.maximumWindowSize);
    }
}

