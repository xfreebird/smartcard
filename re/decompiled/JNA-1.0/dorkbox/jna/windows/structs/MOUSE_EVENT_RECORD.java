/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Structure;
import dorkbox.jna.windows.structs.COORD;
import java.util.Arrays;
import java.util.List;

public class MOUSE_EVENT_RECORD
extends Structure {
    public COORD mousePosition;
    public int buttonState;
    public int controlKeyState;
    public int eventFlags;

    protected List<String> getFieldOrder() {
        return Arrays.asList("mousePosition", "buttonState", "controlKeyState", "eventFlags");
    }
}

