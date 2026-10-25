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
import java.nio.charset.Charset;

public class NSString
extends NSObject {
    private static final Charset UTF8 = Charset.forName("UTF-8");
    private static final Pointer objectClass = ObjectiveC.objc_lookUpClass("NSString");
    private static final Pointer stringWithUTF8String = ObjectiveC.sel_getUid("stringWithUTF8String:");
    private static final Pointer UTF8String = ObjectiveC.sel_getUid("UTF8String");

    static Object asBytes(String string) {
        return (string + "\u0000").getBytes(UTF8);
    }

    public NSString(long peer) {
        super(peer);
    }

    public NSString(String string) {
        this(ObjectiveC.objc_msgSend(objectClass, stringWithUTF8String, NSString.asBytes(string)));
    }

    public String toString() {
        long pointerReference = ObjectiveC.objc_msgSend(this, UTF8String, new Object[0]);
        return new Pointer(pointerReference).getString(0L);
    }
}

