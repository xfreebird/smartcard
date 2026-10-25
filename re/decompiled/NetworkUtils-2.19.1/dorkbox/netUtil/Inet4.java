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
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u0005\u001a\u0004\u0018\u00010\u00062\u0006\u0010\u0007\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\b"}, d2={"Ldorkbox/netUtil/Inet4;", "", "()V", "version", "", "toAddress", "Ljava/net/Inet4Address;", "ip", "NetworkUtils"})
public final class Inet4 {
    @NotNull
    public static final Inet4 INSTANCE = new Inet4();
    @NotNull
    public static final String version = "2.19.1";

    private Inet4() {
    }

    @Nullable
    public final Inet4Address toAddress(@NotNull String ip) {
        Inet4Address inet4Address;
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        if (IPv4.INSTANCE.isValid(ip)) {
            inet4Address = IPv4.INSTANCE.toAddressUnsafe(ip);
        } else {
            Inet4Address inet4Address2;
            try {
                Object object;
                block5: {
                    InetAddress[] inetAddressArray = InetAddress.getAllByName(ip);
                    Intrinsics.checkNotNullExpressionValue((Object)inetAddressArray, (String)"getAllByName(ip)");
                    for (Object object2 : (Object[])inetAddressArray) {
                        InetAddress it = (InetAddress)object2;
                        boolean bl = false;
                        if (!(it instanceof Inet4Address)) continue;
                        object = object2;
                        break block5;
                    }
                    object = null;
                }
                Intrinsics.checkNotNull(object, (String)"null cannot be cast to non-null type java.net.Inet4Address");
                inet4Address2 = (Inet4Address)object;
            }
            catch (UnknownHostException e) {
                inet4Address2 = null;
            }
            inet4Address = inet4Address2;
        }
        return inet4Address;
    }
}

