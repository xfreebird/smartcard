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

public interface FuncCallback
extends Callback {
    public int callback(Pointer var1);
}

