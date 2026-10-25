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
import dorkbox.jna.linux.structs.GTypeInstanceStruct;
import java.util.Arrays;
import java.util.List;

public class GObjectStruct
extends Structure {
    public GTypeInstanceStruct g_type_instance;
    public int ref_count;
    public Pointer qdata;

    protected List<String> getFieldOrder() {
        return Arrays.asList("g_type_instance", "ref_count", "qdata");
    }

    public class ByReference
    extends GObjectStruct
    implements Structure.ByReference {
    }

    public class ByValue
    extends GObjectStruct
    implements Structure.ByValue {
    }
}

