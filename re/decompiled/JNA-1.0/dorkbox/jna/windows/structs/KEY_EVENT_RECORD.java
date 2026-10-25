/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Structure;
import dorkbox.jna.windows.structs.CharUnion;
import java.util.Arrays;
import java.util.List;

public class KEY_EVENT_RECORD
extends Structure {
    public boolean keyDown;
    public short repeatCount;
    public short virtualKeyCode;
    public short virtualScanCode;
    public CharUnion uChar;
    public int controlKeyState;

    protected List<String> getFieldOrder() {
        return Arrays.asList("keyDown", "repeatCount", "virtualKeyCode", "virtualScanCode", "uChar", "controlKeyState");
    }
}

