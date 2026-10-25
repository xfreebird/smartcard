/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.PointerType
 */
package dorkbox.jna.linux;

import com.sun.jna.Pointer;
import com.sun.jna.PointerType;
import dorkbox.jna.linux.GObject;

public class GObjectType
extends PointerType {
    public GObjectType() {
    }

    public GObjectType(Pointer p) {
        super(p);
    }

    protected void finalize() throws Throwable {
        super.finalize();
    }

    public void ref() {
        GObject.g_object_ref(this.getPointer());
    }

    public void unref() {
        GObject.g_object_unref(this.getPointer());
    }
}

