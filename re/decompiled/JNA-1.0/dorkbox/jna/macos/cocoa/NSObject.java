/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.macos.cocoa;

import com.sun.jna.Pointer;
import dorkbox.jna.macos.foundation.ObjectiveC;

public class NSObject
extends Pointer {
    public static final Pointer objectClass = ObjectiveC.objc_lookUpClass("NSObject");
    private static final Pointer alloc = ObjectiveC.sel_getUid("alloc");
    private static final Pointer retain = ObjectiveC.sel_getUid("retain");
    private static final Pointer release = ObjectiveC.sel_getUid("release");

    public NSObject(long peer) {
        super(peer);
        this.retain();
    }

    public NSObject(Pointer pointer) {
        this(Pointer.nativeValue((Pointer)pointer));
    }

    protected void finalize() throws Throwable {
        this.release();
        super.finalize();
    }

    public void alloc() {
        ObjectiveC.objc_msgSend(this, alloc, new Object[0]);
    }

    public void retain() {
        ObjectiveC.objc_msgSend(this, retain, new Object[0]);
    }

    public void release() {
        ObjectiveC.objc_msgSend(this, release, new Object[0]);
    }

    public long asPointer() {
        return Pointer.nativeValue((Pointer)this);
    }
}

