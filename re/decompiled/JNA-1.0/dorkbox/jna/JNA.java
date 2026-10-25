/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Native
 *  com.sun.jna.NativeLibrary
 *  com.sun.jna.win32.W32APIOptions
 *  dorkbox.os.OS
 *  dorkbox.updates.Updates
 */
package dorkbox.jna;

import com.sun.jna.Native;
import com.sun.jna.NativeLibrary;
import com.sun.jna.win32.W32APIOptions;
import dorkbox.os.OS;
import dorkbox.updates.Updates;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public class JNA {
    public static String getVersion() {
        return "1.0";
    }

    public static NativeLibrary register(String libraryName, Class<?> clazz) throws IllegalArgumentException {
        NativeLibrary library;
        HashMap<String, ClassLoader> options = new HashMap<String, ClassLoader>();
        options.put("classloader", clazz.getClassLoader());
        if (OS.INSTANCE.isWindows()) {
            Set entries = W32APIOptions.DEFAULT_OPTIONS.entrySet();
            for (Map.Entry entry : entries) {
                options.put((String)entry.getKey(), (ClassLoader)entry.getValue());
            }
        }
        if ((library = NativeLibrary.getInstance((String)libraryName, options)) == null) {
            throw new IllegalArgumentException(libraryName + " doesn't exist or cannot be loaded.");
        }
        Native.register(clazz, (NativeLibrary)library);
        return library;
    }

    static {
        Updates.INSTANCE.add(JNA.class, "b416694a22ed4a1d9e612a1e9b6c76cf", JNA.getVersion());
    }
}

