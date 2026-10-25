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

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0006\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0016\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\u0006\u0010\b\u001a\u00020\u0004J\u0016\u0010\t\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\u0006\u0010\n\u001a\u00020\u0004J\u001e\u0010\t\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\u0006\u0010\u000b\u001a\u00020\u00042\u0006\u0010\n\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\f"}, d2={"Ldorkbox/netUtil/IfConfig;", "", "()V", "version", "", "assignMac", "", "interfaceName", "interfaceMac", "up", "interfaceCIDR", "interfaceIP", "NetworkUtils"})
public final class IfConfig {
    @NotNull
    public static final IfConfig INSTANCE = new IfConfig();
    @NotNull
    public static final String version = "2.19.1";

    private IfConfig() {
    }

    public final void assignMac(@NotNull String interfaceName, @NotNull String interfaceMac) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        Intrinsics.checkNotNullParameter((Object)interfaceMac, (String)"interfaceMac");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ifconfig", interfaceName, "hw", "ether", interfaceMac};
        Executor.Companion.run(stringArray);
    }

    public final void up(@NotNull String interfaceName, @NotNull String interfaceCIDR) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        Intrinsics.checkNotNullParameter((Object)interfaceCIDR, (String)"interfaceCIDR");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        this.up(interfaceName, "0.0.0.0", interfaceCIDR);
    }

    public final void up(@NotNull String interfaceName, @NotNull String interfaceIP, @NotNull String interfaceCIDR) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        Intrinsics.checkNotNullParameter((Object)interfaceIP, (String)"interfaceIP");
        Intrinsics.checkNotNullParameter((Object)interfaceCIDR, (String)"interfaceCIDR");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ifconfig", interfaceName, interfaceIP + '/' + interfaceCIDR, "up"};
        Executor.Companion.run(stringArray);
    }
}

