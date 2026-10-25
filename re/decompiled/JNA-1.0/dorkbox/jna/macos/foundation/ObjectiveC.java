/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Callback
 *  com.sun.jna.Library
 *  com.sun.jna.Native
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.macos.foundation;

import com.sun.jna.Callback;
import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.Pointer;

public class ObjectiveC {
    private static final Objc INSTANCE = (Objc)Native.load((String)"objc", Objc.class);

    public static Pointer objc_lookUpClass(String name) {
        return INSTANCE.objc_lookUpClass(name);
    }

    public static long objc_msgSend(Pointer self, Pointer op, Object ... args) {
        return INSTANCE.objc_msgSend(self, op, args);
    }

    public static Pointer objc_allocateClassPair(Pointer superClass, String name, long extraBytes) {
        return INSTANCE.objc_allocateClassPair(superClass, name, extraBytes);
    }

    public static void objc_registerClassPair(Pointer cls) {
        INSTANCE.objc_registerClassPair(cls);
    }

    public static Pointer class_createInstance(Pointer cls, int extraBytes) {
        return INSTANCE.class_createInstance(cls, extraBytes);
    }

    public static boolean class_addMethod(Pointer cls, Pointer name, Callback imp, String types) {
        return INSTANCE.class_addMethod(cls, name, imp, types);
    }

    public static Pointer sel_getUid(String str) {
        return INSTANCE.sel_getUid(str);
    }

    public static Pointer sel_registerName(String str) {
        return INSTANCE.sel_registerName(str);
    }

    static interface Objc
    extends Library {
        public Pointer objc_lookUpClass(String var1);

        public long objc_msgSend(Pointer var1, Pointer var2, Object ... var3);

        public Pointer objc_allocateClassPair(Pointer var1, String var2, long var3);

        public void objc_registerClassPair(Pointer var1);

        public Pointer class_createInstance(Pointer var1, int var2);

        public boolean class_addMethod(Pointer var1, Pointer var2, Callback var3, String var4);

        public Pointer sel_getUid(String var1);

        public Pointer sel_registerName(String var1);
    }
}

