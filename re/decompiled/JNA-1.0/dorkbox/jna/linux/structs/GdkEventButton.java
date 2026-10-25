/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.Structure
 */
package dorkbox.jna.linux.structs;

import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import java.util.Arrays;
import java.util.List;

public class GdkEventButton
extends Structure {
    public int type;
    public Pointer window;
    public int send_event;
    public int time;
    public double x;
    public double y;
    public Pointer axes;
    public int state;
    public int button;
    public Pointer device;
    public double x_root;
    public double y_root;

    protected List<String> getFieldOrder() {
        return Arrays.asList("type", "window", "send_event", "time", "x", "y", "axes", "state", "button", "device", "x_root", "y_root");
    }
}

