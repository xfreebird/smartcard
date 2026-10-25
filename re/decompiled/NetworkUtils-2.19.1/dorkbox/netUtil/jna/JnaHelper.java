/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Native
 *  com.sun.jna.NativeLibrary
 *  com.sun.jna.win32.W32APIOptions
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil.jna;

import com.sun.jna.Native;
import com.sun.jna.NativeLibrary;
import com.sun.jna.win32.W32APIOptions;
import dorkbox.netUtil.Common;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001e\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001a\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\n\u0010\u0007\u001a\u0006\u0012\u0002\b\u00030\b\u00a8\u0006\t"}, d2={"Ldorkbox/netUtil/jna/JnaHelper;", "", "()V", "register", "Lcom/sun/jna/NativeLibrary;", "libraryName", "", "clazz", "Ljava/lang/Class;", "NetworkUtils"})
public final class JnaHelper {
    @NotNull
    public static final JnaHelper INSTANCE = new JnaHelper();

    private JnaHelper() {
    }

    @NotNull
    public final NativeLibrary register(@NotNull String libraryName, @NotNull Class<?> clazz) throws IllegalArgumentException {
        Object object;
        Intrinsics.checkNotNullParameter((Object)libraryName, (String)"libraryName");
        Intrinsics.checkNotNullParameter(clazz, (String)"clazz");
        Map options = new HashMap();
        options.put("classloader", clazz.getClassLoader());
        if (Common.INSTANCE.getOS_WINDOWS()) {
            Set entries = W32APIOptions.DEFAULT_OPTIONS.entrySet();
            object = entries.iterator();
            while (object.hasNext()) {
                Map.Entry entry = (Map.Entry)object.next();
                String key = (String)entry.getKey();
                Object value = entry.getValue();
                options.put(key, value);
            }
        }
        if ((object = NativeLibrary.getInstance((String)libraryName, (Map)options)) == null) {
            throw new IllegalArgumentException(libraryName + " doesn't exist or cannot be loaded.");
        }
        Object library = object;
        Native.register(clazz, (NativeLibrary)library);
        return library;
    }
}

