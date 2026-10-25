/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.Structure
 *  kotlin.Metadata
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.JvmField
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil.jna.windows.structs;

import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import dorkbox.netUtil.jna.windows.structs.SOCKADDR_IN;
import dorkbox.netUtil.jna.windows.structs.SOCKADDR_IN6;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.List;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.JvmField;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000*\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u0000 \f2\u00020\u0001:\u0001\fB\u0005\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\bH\u0014J\b\u0010\n\u001a\u0004\u0018\u00010\u000bR\u0012\u0010\u0003\u001a\u00020\u00048\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0005\u001a\u0004\u0018\u00010\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\r"}, d2={"Ldorkbox/netUtil/jna/windows/structs/SOCKET_ADDRESS;", "Lcom/sun/jna/Structure;", "()V", "iSockaddrLength", "", "lpSockaddr", "Lcom/sun/jna/Pointer;", "getFieldOrder", "", "", "toAddress", "Ljava/net/InetAddress;", "Companion", "NetworkUtils"})
public final class SOCKET_ADDRESS
extends Structure {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @JvmField
    @Nullable
    public Pointer lpSockaddr;
    @JvmField
    public int iSockaddrLength;
    public static final int AF_INET = 2;
    public static final int AF_INET6 = 23;

    @Nullable
    public final InetAddress toAddress() throws UnknownHostException {
        Pointer pointer = this.lpSockaddr;
        Intrinsics.checkNotNull((Object)pointer);
        switch (pointer.getShort(0L)) {
            case 2: {
                Pointer pointer2 = this.lpSockaddr;
                Intrinsics.checkNotNull((Object)pointer2);
                SOCKADDR_IN in4 = new SOCKADDR_IN(pointer2);
                return InetAddress.getByAddress(in4.sin_addr);
            }
            case 23: {
                Pointer pointer3 = this.lpSockaddr;
                Intrinsics.checkNotNull((Object)pointer3);
                SOCKADDR_IN6 in6 = new SOCKADDR_IN6(pointer3);
                return Inet6Address.getByAddress("", in6.sin6_addr, in6.sin6_scope_id);
            }
        }
        return null;
    }

    @NotNull
    protected List<String> getFieldOrder() {
        Object[] objectArray = new String[]{"lpSockaddr", "iSockaddrLength"};
        return CollectionsKt.listOf((Object[])objectArray);
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0006"}, d2={"Ldorkbox/netUtil/jna/windows/structs/SOCKET_ADDRESS$Companion;", "", "()V", "AF_INET", "", "AF_INET6", "NetworkUtils"})
    public static final class Companion {
        private Companion() {
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

