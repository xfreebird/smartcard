/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.executor.Executor
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil;

import dorkbox.executor.Executor;
import dorkbox.netUtil.Common;
import java.util.HashMap;
import java.util.Map;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010%\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0006\u0010\u0007\u001a\u00020\bJ\u0018\u0010\t\u001a\u00020\b2\b\u0010\n\u001a\u0004\u0018\u00010\u00052\u0006\u0010\u000b\u001a\u00020\fJ\u000e\u0010\r\u001a\u00020\b2\u0006\u0010\n\u001a\u00020\u0005J\u0016\u0010\u000e\u001a\u00020\u00052\u0006\u0010\n\u001a\u00020\u00052\u0006\u0010\u000f\u001a\u00020\u0010J\u0016\u0010\u0011\u001a\u00020\b2\u0006\u0010\n\u001a\u00020\u00052\u0006\u0010\u0012\u001a\u00020\u0005J\u000e\u0010\u0013\u001a\u00020\b2\u0006\u0010\n\u001a\u00020\u0005R\u001a\u0010\u0003\u001a\u000e\u0012\u0004\u0012\u00020\u0005\u0012\u0004\u0012\u00020\u00050\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0005X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0014"}, d2={"Ldorkbox/netUtil/Iface;", "", "()V", "ifToIp", "", "", "version", "addLoopback", "", "assignCIDR", "interfaceName", "cidr", "", "down", "getIpFromIf", "isOnClientConnect", "", "setMac", "interfaceMac", "up", "NetworkUtils"})
public final class Iface {
    @NotNull
    public static final Iface INSTANCE = new Iface();
    @NotNull
    public static final String version = "2.19.1";
    @NotNull
    private static final Map<String, String> ifToIp = new HashMap();

    private Iface() {
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final String getIpFromIf(@NotNull String interfaceName, boolean isOnClientConnect) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (Common.INSTANCE.getOS_LINUX()) {
            if (isOnClientConnect) {
                String str;
                String[] stringArray = new String[]{"/sbin/ifconfig", interfaceName};
                String ifaceInfo = Executor.Companion.run(stringArray);
                int index = StringsKt.indexOf$default((CharSequence)ifaceInfo, (String)(str = "inet addr:"), (int)0, (boolean)false, (int)6, null);
                if (index > -1) {
                    String string = ifaceInfo.substring(index += str.length(), StringsKt.indexOf$default((CharSequence)ifaceInfo, (String)" ", (int)index, (boolean)false, (int)4, null));
                    Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                    String possibleAddr = string;
                    Common.INSTANCE.getLogger$NetworkUtils().debug("Found on '{}' possible addr '{}' : ADD", (Object)interfaceName, (Object)possibleAddr);
                    Map<String, String> map = ifToIp;
                    synchronized (map) {
                        boolean bl = false;
                        String string2 = ifToIp.put(interfaceName, possibleAddr);
                    }
                    return possibleAddr;
                }
            } else {
                String possibleAddr = null;
                Map<String, String> map = ifToIp;
                synchronized (map) {
                    boolean bl = false;
                    possibleAddr = ifToIp.remove(interfaceName);
                    Unit unit = Unit.INSTANCE;
                }
                Common.INSTANCE.getLogger$NetworkUtils().debug("Found on '{}' possible addr '{}' : REMOVE", (Object)interfaceName, (Object)possibleAddr);
                if (possibleAddr != null) {
                    return possibleAddr;
                }
            }
        } else {
            throw new RuntimeException("NOT IMPL.");
        }
        return "";
    }

    public final void down(@NotNull String interfaceName) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "link", "set", "dev", interfaceName, "down"};
        Executor.Companion.run(stringArray);
    }

    public final void up(@NotNull String interfaceName) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "link", "set", "dev", interfaceName, "up"};
        Executor.Companion.run(stringArray);
    }

    public final void setMac(@NotNull String interfaceName, @NotNull String interfaceMac) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        Intrinsics.checkNotNullParameter((Object)interfaceMac, (String)"interfaceMac");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "link", "set", "dev", interfaceName, "address", interfaceMac};
        Executor.Companion.run(stringArray);
    }

    public final void assignCIDR(@Nullable String interfaceName, int cidr) {
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ifconfig", interfaceName + " 0.0.0.0/" + cidr + " up"};
        Executor.Companion.run(stringArray);
    }

    public final void addLoopback() {
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "link", "set", "dev", "lo", "up"};
        Executor.Companion.run(stringArray);
        stringArray = new String[]{"/sbin/ip", "addr", "add", "127.0.0.1", "dev", "lo"};
        Executor.Companion.run(stringArray);
    }
}

