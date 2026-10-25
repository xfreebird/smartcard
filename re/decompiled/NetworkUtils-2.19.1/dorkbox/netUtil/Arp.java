/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.executor.Executor
 *  kotlin.Metadata
 *  kotlin.io.FilesKt
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil;

import dorkbox.executor.Executor;
import dorkbox.netUtil.Common;
import java.io.File;
import kotlin.Metadata;
import kotlin.io.FilesKt;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0006\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001e\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\u0006\u0010\b\u001a\u00020\u00042\u0006\u0010\t\u001a\u00020\u0004J\u000e\u0010\n\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u0004J\u000e\u0010\u000b\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\f"}, d2={"Ldorkbox/netUtil/Arp;", "", "()V", "version", "", "add", "", "interfaceName", "targetIpAddress", "targetMacAddress", "proxyAdd", "proxyDel", "NetworkUtils"})
public final class Arp {
    @NotNull
    public static final Arp INSTANCE = new Arp();
    @NotNull
    public static final String version = "2.19.1";

    private Arp() {
    }

    public final void proxyAdd(@NotNull String interfaceName) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (Common.INSTANCE.getOS_LINUX()) {
            File file = new File("/proc/sys/net/ipv4/conf/" + interfaceName + "/proxy_arp");
            if (!StringsKt.contains$default((CharSequence)FilesKt.readText$default((File)file, null, (int)1, null), (CharSequence)"1", (boolean)false, (int)2, null)) {
                FilesKt.appendText$default((File)file, (String)"1", null, (int)2, null);
            }
        } else {
            throw new RuntimeException("NOT IMPL.");
        }
    }

    public final void proxyDel(@NotNull String interfaceName) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        File file = new File("/proc/sys/net/ipv4/conf/" + interfaceName + "/proxy_arp");
        file.delete();
    }

    public final void add(@NotNull String interfaceName, @NotNull String targetIpAddress, @NotNull String targetMacAddress) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        Intrinsics.checkNotNullParameter((Object)targetIpAddress, (String)"targetIpAddress");
        Intrinsics.checkNotNullParameter((Object)targetMacAddress, (String)"targetMacAddress");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/usr/sbin/arp", "-i", interfaceName, "-s", targetIpAddress, targetMacAddress};
        Executor.startBlocking$default((Executor)new Executor().command(stringArray), (long)0L, null, (int)3, null);
    }
}

