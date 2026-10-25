/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByReference
 *  com.sun.jna.Union
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Structure;
import com.sun.jna.Union;
import dorkbox.jna.windows.structs.KEY_EVENT_RECORD;
import dorkbox.jna.windows.structs.MOUSE_EVENT_RECORD;
import java.util.Arrays;
import java.util.List;

public class INPUT_RECORD
extends Structure {
    public static final short KEY_EVENT = 1;
    public static final short MOUSE_EVENT = 2;
    public short EventType;
    public EventUnion Event;

    public void read() {
        this.readField("EventType");
        switch (this.EventType) {
            case 1: {
                this.Event.setType(KEY_EVENT_RECORD.class);
                break;
            }
            case 2: {
                this.Event.setType(MOUSE_EVENT_RECORD.class);
            }
        }
        super.read();
    }

    protected List<String> getFieldOrder() {
        return Arrays.asList("EventType", "Event");
    }

    public static class EventUnion
    extends Union {
        public KEY_EVENT_RECORD KeyEvent;
        public MOUSE_EVENT_RECORD MouseEvent;
    }

    public static class ByReference
    extends INPUT_RECORD
    implements Structure.ByReference {
    }
}

