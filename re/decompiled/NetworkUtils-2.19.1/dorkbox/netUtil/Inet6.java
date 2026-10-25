/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil;

import dorkbox.netUtil.IPv4;
import dorkbox.netUtil.IPv6;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000 \n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0000\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001a\u0010\u0005\u001a\u0004\u0018\u00010\u00062\u0006\u0010\u0007\u001a\u00020\u00042\b\b\u0002\u0010\b\u001a\u00020\tR\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\n"}, d2={"Ldorkbox/netUtil/Inet6;", "", "()V", "version", "", "toAddress", "Ljava/net/Inet6Address;", "ip", "ipv4Mapped", "", "NetworkUtils"})
public final class Inet6 {
    @NotNull
    public static final Inet6 INSTANCE = new Inet6();
    @NotNull
    public static final String version = "2.19.1";

    private Inet6() {
    }

    @Nullable
    public final Inet6Address toAddress(@NotNull String ip, boolean ipv4Mapped) {
        Inet6Address inet6Address;
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        if (IPv6.INSTANCE.isValid(ip) || ipv4Mapped && IPv4.INSTANCE.isValid(ip)) {
            inet6Address = IPv6.INSTANCE.toAddress(ip, ipv4Mapped);
        } else {
            Inet6Address inet6Address2;
            try {
                Object object;
                block5: {
                    InetAddress[] inetAddressArray = InetAddress.getAllByName(ip);
                    Intrinsics.checkNotNullExpressionValue((Object)inetAddressArray, (String)"getAllByName(ip)");
                    for (Object object2 : (Object[])inetAddressArray) {
                        InetAddress it = (InetAddress)object2;
                        boolean bl = false;
                        if (!(it instanceof Inet6Address)) continue;
                        object = object2;
                        break block5;
                    }
                    object = null;
                }
                Intrinsics.checkNotNull(object, (String)"null cannot be cast to non-null type java.net.Inet6Address");
                inet6Address2 = (Inet6Address)object;
            }
            catch (UnknownHostException e) {
                inet6Address2 = null;
            }
            inet6Address = inet6Address2;
        }
        return inet6Address;
    }

    public static /* synthetic */ Inet6Address toAddress$default(Inet6 inet6, String string, boolean bl, int n, Object object) {
        if ((n & 2) != 0) {
            bl = true;
        }
        return inet6.toAddress(string, bl);
    }
}

