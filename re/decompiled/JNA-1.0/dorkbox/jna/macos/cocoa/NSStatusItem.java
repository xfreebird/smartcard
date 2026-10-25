/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.macos.cocoa;

import com.sun.jna.Pointer;
import dorkbox.jna.macos.cocoa.NSImage;
import dorkbox.jna.macos.cocoa.NSMenu;
import dorkbox.jna.macos.cocoa.NSObject;
import dorkbox.jna.macos.cocoa.NSString;
import dorkbox.jna.macos.foundation.ObjectiveC;

public class NSStatusItem
extends NSObject {
    private static final Pointer setHighlightMode = ObjectiveC.sel_getUid("setHighlightMode:");
    private static final Pointer setToolTip = ObjectiveC.sel_getUid("setToolTip:");
    private static final Pointer setMenu = ObjectiveC.sel_getUid("setMenu:");
    private static final Pointer setImage = ObjectiveC.sel_getUid("setImage:");

    public NSStatusItem(long peer) {
        super(peer);
    }

    public void setHighlightMode(boolean highlight) {
        ObjectiveC.objc_msgSend(this, setHighlightMode, highlight);
    }

    public void setImage(NSImage image) {
        ObjectiveC.objc_msgSend(this, setImage, new Object[]{image});
    }

    public void setMenu(NSMenu menu) {
        ObjectiveC.objc_msgSend(this, setMenu, new Object[]{menu});
    }

    public void setToolTip(NSString tooltip) {
        ObjectiveC.objc_msgSend(this, setToolTip, new Object[]{tooltip});
    }
}

