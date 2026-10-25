/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.ptr.IntByReference
 *  kotlin.Metadata
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil.jna.windows;

import com.sun.jna.Pointer;
import com.sun.jna.ptr.IntByReference;
import dorkbox.netUtil.jna.JnaHelper;
import kotlin.Metadata;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\"\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0011\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J7\u0010\u0012\u001a\u00020\u00042\u0006\u0010\u0013\u001a\u00020\u00042\u0006\u0010\u0014\u001a\u00020\u00042\b\u0010\u0015\u001a\u0004\u0018\u00010\u00162\b\u0010\u0017\u001a\u0004\u0018\u00010\u00162\b\u0010\u0018\u001a\u0004\u0018\u00010\u0019H\u0086 R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\f\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000e\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000f\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0010\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0011\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u001a"}, d2={"Ldorkbox/netUtil/jna/windows/IPHlpAPI;", "", "()V", "AF_INET", "", "AF_INET6", "AF_UNSPEC", "GAA_FLAG_INCLUDE_ALL_COMPARTMENTS", "GAA_FLAG_INCLUDE_ALL_INTERFACES", "GAA_FLAG_INCLUDE_GATEWAYS", "GAA_FLAG_INCLUDE_PREFIX", "GAA_FLAG_INCLUDE_TUNNEL_BINDINGORDER", "GAA_FLAG_INCLUDE_WINS_INFO", "GAA_FLAG_SKIP_ANYCAST", "GAA_FLAG_SKIP_DNS_SERVER", "GAA_FLAG_SKIP_FRIENDLY_NAME", "GAA_FLAG_SKIP_MULTICAST", "GAA_FLAG_SKIP_UNICAST", "GetAdaptersAddresses", "family", "flags", "reserved", "Lcom/sun/jna/Pointer;", "adapterAddresses", "sizePointer", "Lcom/sun/jna/ptr/IntByReference;", "NetworkUtils"})
public final class IPHlpAPI {
    @NotNull
    public static final IPHlpAPI INSTANCE = new IPHlpAPI();
    public static final int AF_UNSPEC = 0;
    public static final int AF_INET = 2;
    public static final int AF_INET6 = 23;
    public static final int GAA_FLAG_SKIP_UNICAST = 1;
    public static final int GAA_FLAG_SKIP_ANYCAST = 2;
    public static final int GAA_FLAG_SKIP_MULTICAST = 4;
    public static final int GAA_FLAG_SKIP_DNS_SERVER = 8;
    public static final int GAA_FLAG_INCLUDE_PREFIX = 16;
    public static final int GAA_FLAG_SKIP_FRIENDLY_NAME = 32;
    public static final int GAA_FLAG_INCLUDE_WINS_INFO = 64;
    public static final int GAA_FLAG_INCLUDE_GATEWAYS = 128;
    public static final int GAA_FLAG_INCLUDE_ALL_INTERFACES = 256;
    public static final int GAA_FLAG_INCLUDE_ALL_COMPARTMENTS = 512;
    public static final int GAA_FLAG_INCLUDE_TUNNEL_BINDINGORDER = 1024;

    private IPHlpAPI() {
    }

    public final native int GetAdaptersAddresses(int var1, int var2, @Nullable Pointer var3, @Nullable Pointer var4, @Nullable IntByReference var5);

    static {
        JnaHelper.INSTANCE.register("IPHlpAPI", IPHlpAPI.class);
    }
}

