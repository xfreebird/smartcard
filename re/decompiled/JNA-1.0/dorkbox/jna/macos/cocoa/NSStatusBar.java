/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.macos.cocoa;

import com.sun.jna.Pointer;
import dorkbox.jna.macos.cocoa.NSObject;
import dorkbox.jna.macos.cocoa.NSStatusItem;
import dorkbox.jna.macos.foundation.ObjectiveC;

public class NSStatusBar
extends NSObject {
    public static final float NSVariableStatusItemLength = -1.0f;
    public static final float NSSquareStatusItemLength = -2.0f;
    static Pointer objectClass = ObjectiveC.objc_lookUpClass("NSStatusBar");
    static Pointer systemStatusBar = ObjectiveC.sel_getUid("systemStatusBar");
    static Pointer statusItemWithLength = ObjectiveC.sel_getUid("statusItemWithLength:");
    static Pointer removeStatusItem = ObjectiveC.sel_getUid("removeStatusItem:");

    public NSStatusBar(long peer) {
        super(peer);
    }

    public static NSStatusBar systemStatusBar() {
        return new NSStatusBar(ObjectiveC.objc_msgSend(objectClass, systemStatusBar, new Object[0]));
    }

    public NSStatusItem newStatusItem() {
        long result = ObjectiveC.objc_msgSend(this, statusItemWithLength, Float.valueOf(-2.0f));
        return result != 0L ? new NSStatusItem(result) : null;
    }

    public void removeStatusItem(NSStatusItem statusItem) {
        ObjectiveC.objc_msgSend(this, removeStatusItem, new Object[]{statusItem});
    }
}

