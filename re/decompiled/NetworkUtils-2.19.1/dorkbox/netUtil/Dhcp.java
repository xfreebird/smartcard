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
import java.io.File;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0004\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0016\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\u0006\u0010\b\u001a\u00020\u0004J\u0016\u0010\t\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\u0006\u0010\b\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\n"}, d2={"Ldorkbox/netUtil/Dhcp;", "", "()V", "version", "", "start", "", "id", "interfaceName", "stop", "NetworkUtils"})
public final class Dhcp {
    @NotNull
    public static final Dhcp INSTANCE = new Dhcp();
    @NotNull
    public static final String version = "2.19.1";

    private Dhcp() {
    }

    public final void start(@NotNull String id, @NotNull String interfaceName) {
        Intrinsics.checkNotNullParameter((Object)id, (String)"id");
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        this.stop(id, interfaceName);
        String dhcpPidFile = "/var/run/dhclient-" + id + ".pid";
        String[] stringArray = new String[]{"/sbin/dhclient", "-pf", dhcpPidFile, interfaceName};
        Executor.startBlocking$default((Executor)new Executor().command(stringArray), (long)0L, null, (int)3, null);
    }

    public final void stop(@NotNull String id, @NotNull String interfaceName) {
        String dhcpPidFile;
        Intrinsics.checkNotNullParameter((Object)id, (String)"id");
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (Common.INSTANCE.getOS_LINUX()) {
            dhcpPidFile = "/var/run/dhclient-" + id + ".pid";
            String[] stringArray = new String[]{"/sbin/dhclient", "-r -pf", dhcpPidFile, interfaceName};
            Executor.startBlocking$default((Executor)new Executor().command(stringArray), (long)0L, null, (int)3, null);
            try {
                Thread.sleep(500L);
            }
            catch (InterruptedException e) {
                e.printStackTrace();
            }
        } else {
            throw new RuntimeException("NOT IMPL.");
        }
        new File(dhcpPidFile).delete();
    }
}

