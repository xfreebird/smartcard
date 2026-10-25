/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.macos.cocoa;

import com.sun.jna.Pointer;
import dorkbox.jna.macos.cocoa.NSImage;
import dorkbox.jna.macos.cocoa.NSInteger;
import dorkbox.jna.macos.cocoa.NSMenu;
import dorkbox.jna.macos.cocoa.NSObject;
import dorkbox.jna.macos.cocoa.NSString;
import dorkbox.jna.macos.foundation.ObjectiveC;

public class NSMenuItem
extends NSObject {
    private static final Pointer objectClass = ObjectiveC.objc_lookUpClass("NSMenuItem");
    private static final Pointer setTitle = ObjectiveC.sel_getUid("setTitle:");
    private static final Pointer toolTip = ObjectiveC.sel_getUid("toolTip");
    private static final Pointer setKeyEquivalent = ObjectiveC.sel_getUid("setKeyEquivalent:");
    private static final Pointer setIndentationLevel = ObjectiveC.sel_getUid("setIndentationLevel:");
    private static final Pointer setImage = ObjectiveC.sel_getUid("setImage:");
    private static final Pointer setOnStateImage = ObjectiveC.sel_getUid("setOnStateImage:");
    private static final Pointer setEnabled = ObjectiveC.sel_getUid("setEnabled:");
    private static final Pointer separatorItem = ObjectiveC.sel_getUid("separatorItem");
    private static final Pointer setSubmenu = ObjectiveC.sel_getUid("setSubmenu:");
    private static final Pointer setState = ObjectiveC.sel_getUid("setState:");
    private static final Pointer setTarget = ObjectiveC.sel_getUid("setTarget:");
    private static final Pointer setAction = ObjectiveC.sel_getUid("setAction:");

    public NSMenuItem() {
        super(ObjectiveC.class_createInstance(objectClass, 0));
    }

    public NSMenuItem(long peer) {
        super(peer);
    }

    public static NSMenuItem separatorItem() {
        return new NSMenuItem(ObjectiveC.objc_msgSend(objectClass, separatorItem, new Object[0]));
    }

    public void setTitle(NSString title) {
        ObjectiveC.objc_msgSend(this, setTitle, new Object[]{title});
    }

    public NSString setToolTip(NSString tooltip) {
        return new NSString(ObjectiveC.objc_msgSend(this, toolTip, new Object[]{tooltip}));
    }

    public void setIndentationLevel(NSInteger indentationLevel) {
        ObjectiveC.objc_msgSend(this, setIndentationLevel, new Object[]{indentationLevel});
    }

    public void setKeyEquivalent(NSString characters) {
        ObjectiveC.objc_msgSend(this, setKeyEquivalent, new Object[]{characters});
    }

    public void setImage(NSImage image) {
        ObjectiveC.objc_msgSend(this, setImage, new Object[]{image});
    }

    public void setOnStateImage(NSImage image) {
        ObjectiveC.objc_msgSend(this, setOnStateImage, new Object[]{image});
    }

    public void setEnabled(boolean enabled) {
        ObjectiveC.objc_msgSend(this, setEnabled, enabled);
    }

    public void setSubmenu(NSMenu submenu) {
        ObjectiveC.objc_msgSend(this, setSubmenu, new Object[]{submenu});
    }

    public void setState(int state) {
        ObjectiveC.objc_msgSend(this, setState, state);
    }

    public void setTarget(NSObject target) {
        ObjectiveC.objc_msgSend(this, setTarget, new Object[]{target});
    }

    public void setAction(Pointer pointer) {
        ObjectiveC.objc_msgSend(this, setAction, pointer);
    }
}

