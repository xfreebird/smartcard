/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.IntegerType
 *  com.sun.jna.Native
 */
package dorkbox.jna.windows;

import com.sun.jna.IntegerType;
import com.sun.jna.Native;

public class Parameter
extends IntegerType {
    public Parameter() {
        this(0L);
    }

    public Parameter(long value) {
        super(Native.POINTER_SIZE, value);
    }
}

