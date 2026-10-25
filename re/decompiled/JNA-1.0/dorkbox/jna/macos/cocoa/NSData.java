/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.macos.cocoa;

import com.sun.jna.Pointer;
import dorkbox.jna.macos.cocoa.NSObject;
import dorkbox.jna.macos.foundation.ObjectiveC;

public class NSData
extends NSObject {
    private static final Pointer objectClass = ObjectiveC.objc_lookUpClass("NSData");
    private static final Pointer dataWithBytesLength = ObjectiveC.sel_getUid("dataWithBytes:length:");

    public NSData(byte[] data) {
        super(ObjectiveC.objc_msgSend(objectClass, dataWithBytesLength, data, data.length));
    }
}

