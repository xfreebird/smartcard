/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByReference
 *  com.sun.jna.Structure$ByValue
 */
package dorkbox.jna.linux.structs;

import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import java.util.Arrays;
import java.util.List;

public class GTypeInstanceStruct
extends Structure {
    public Pointer g_class;

    protected List<String> getFieldOrder() {
        return Arrays.asList("g_class");
    }

    public class ByReference
    extends GTypeInstanceStruct
    implements Structure.ByReference {
    }

    public class ByValue
    extends GTypeInstanceStruct
    implements Structure.ByValue {
    }
}

