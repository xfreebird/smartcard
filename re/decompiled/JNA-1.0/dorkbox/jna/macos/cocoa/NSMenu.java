/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.macos.cocoa;

import com.sun.jna.Pointer;
import dorkbox.jna.macos.cocoa.NSMenuItem;
import dorkbox.jna.macos.cocoa.NSObject;
import dorkbox.jna.macos.foundation.ObjectiveC;

public class NSMenu
extends NSObject {
    private static final Pointer objectClass = ObjectiveC.objc_lookUpClass("NSMenu");
    private static final Pointer addItem = ObjectiveC.sel_getUid("addItem:");
    private static final Pointer removeItem = ObjectiveC.sel_getUid("removeItem:");
    private static final Pointer setAutoenablesItems = ObjectiveC.sel_getUid("setAutoenablesItems:");
    private static final Pointer itemAtIndex = ObjectiveC.sel_getUid("itemAtIndex:");
    private static final Pointer insertItemAtIndex = ObjectiveC.sel_getUid("insertItem:atIndex:");

    public NSMenu() {
        super(ObjectiveC.class_createInstance(objectClass, 0));
        this.setAutoEnablesItems(true);
    }

    public void addItem(NSMenuItem newItem) {
        ObjectiveC.objc_msgSend(this, addItem, new Object[]{newItem});
    }

    public void insertItemAtIndex(NSMenuItem newItem, int index) {
        ObjectiveC.objc_msgSend(this, insertItemAtIndex, new Object[]{newItem, index});
    }

    public NSMenuItem itemAtIndex(int index) {
        return new NSMenuItem(ObjectiveC.objc_msgSend(this, itemAtIndex, index));
    }

    public void setAutoEnablesItems(boolean enable) {
        ObjectiveC.objc_msgSend(this, setAutoenablesItems, !enable);
    }

    public void removeItem(NSMenuItem anItem) {
        ObjectiveC.objc_msgSend(this, removeItem, new Object[]{anItem});
    }
}

