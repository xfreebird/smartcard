/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Callback
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.linux;

import com.sun.jna.Callback;
import com.sun.jna.Pointer;
import dorkbox.jna.linux.structs.GdkEventButton;

public interface GEventCallback
extends Callback {
    public void callback(Pointer var1, GdkEventButton var2);
}

