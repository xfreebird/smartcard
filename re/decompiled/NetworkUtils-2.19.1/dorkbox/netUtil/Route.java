/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.executor.Executor
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil;

import dorkbox.executor.Executor;
import dorkbox.netUtil.Common;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0005\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001e\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\u0006\u0010\b\u001a\u00020\u00042\u0006\u0010\t\u001a\u00020\u0004J\u0006\u0010\n\u001a\u00020\u0006R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u000b"}, d2={"Ldorkbox/netUtil/Route;", "", "()V", "version", "", "add", "", "targetIpAndCidr", "hostIP", "hostInterface", "flush", "NetworkUtils"})
public final class Route {
    @NotNull
    public static final Route INSTANCE = new Route();
    @NotNull
    public static final String version = "2.19.1";

    private Route() {
    }

    public final void flush() {
        String[] stringArray = new String[]{"/sbin/ip", "route", "flush", "cache"};
        Executor.Companion.run(stringArray);
    }

    public final void add(@NotNull String targetIpAndCidr, @NotNull String hostIP, @NotNull String hostInterface) {
        Intrinsics.checkNotNullParameter((Object)targetIpAndCidr, (String)"targetIpAndCidr");
        Intrinsics.checkNotNullParameter((Object)hostIP, (String)"hostIP");
        Intrinsics.checkNotNullParameter((Object)hostInterface, (String)"hostInterface");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "route", "add", targetIpAndCidr, "via", hostIP, "dev", hostInterface};
        Executor.Companion.run(stringArray);
    }
}

