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

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0006\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0016\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\u0006\u0010\b\u001a\u00020\u0004J\u0016\u0010\t\u001a\u00020\u00062\u0006\u0010\n\u001a\u00020\u00042\u0006\u0010\b\u001a\u00020\u0004J\u000e\u0010\u000b\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\f"}, d2={"Ldorkbox/netUtil/VirtualEth;", "", "()V", "version", "", "add", "", "host", "guest", "assignNameSpace", "nameSpace", "delete", "NetworkUtils"})
public final class VirtualEth {
    @NotNull
    public static final VirtualEth INSTANCE = new VirtualEth();
    @NotNull
    public static final String version = "2.19.1";

    private VirtualEth() {
    }

    public final void add(@NotNull String host, @NotNull String guest) {
        Intrinsics.checkNotNullParameter((Object)host, (String)"host");
        Intrinsics.checkNotNullParameter((Object)guest, (String)"guest");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "link", "add", "name", host, "type", "veth", "peer", "name", guest};
        Executor.startBlocking$default((Executor)new Executor().command(stringArray), (long)0L, null, (int)3, null);
    }

    public final void delete(@NotNull String host) {
        Intrinsics.checkNotNullParameter((Object)host, (String)"host");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "link", "del", host};
        Executor.startBlocking$default((Executor)new Executor().command(stringArray), (long)0L, null, (int)3, null);
    }

    public final void assignNameSpace(@NotNull String nameSpace, @NotNull String guest) {
        Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
        Intrinsics.checkNotNullParameter((Object)guest, (String)"guest");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "link", "set", guest, "netns", nameSpace};
        Executor.startBlocking$default((Executor)new Executor().command(stringArray), (long)0L, null, (int)3, null);
    }
}

