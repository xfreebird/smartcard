/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.executor.Executor
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil;

import dorkbox.executor.Executor;
import dorkbox.netUtil.Common;
import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010%\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0002\b\t\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0010\u0011\n\u0002\b\u0004\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u0002\u0017\u0018B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0007\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\u0005J\u000e\u0010\n\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\u0005J\u000e\u0010\u000b\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\u0005J\u001e\u0010\f\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\u00052\u0006\u0010\r\u001a\u00020\u00052\u0006\u0010\u000e\u001a\u00020\u0005J\u001e\u0010\u000f\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\u00052\u0006\u0010\r\u001a\u00020\u00052\u0006\u0010\u000e\u001a\u00020\u0005J\u001e\u0010\u0010\u001a\u00020\u00052\u0006\u0010\t\u001a\u00020\u00052\u0006\u0010\u000e\u001a\u00020\u00052\u0006\u0010\u0011\u001a\u00020\u0012J'\u0010\u0013\u001a\u00020\u00052\u0006\u0010\t\u001a\u00020\u00052\u0012\u0010\u0014\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050\u0015\"\u00020\u0005\u00a2\u0006\u0002\u0010\u0016R&\u0010\u0003\u001a\u001a\u0012\u0004\u0012\u00020\u0005\u0012\u0010\u0012\u000e\u0012\u0004\u0012\u00020\u0005\u0012\u0004\u0012\u00020\u00050\u00040\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0005X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0019"}, d2={"Ldorkbox/netUtil/NameSpace;", "", "()V", "nameSpaceToIifToIp", "", "", "version", "add", "", "nameSpace", "addLoopback", "delete", "dhcpStart", "id", "interfaceName", "dhcpStop", "getIpFromIf", "isOnClientConnect", "", "run", "args", "", "(Ljava/lang/String;[Ljava/lang/String;)Ljava/lang/String;", "Dhcp", "Route", "NetworkUtils"})
public final class NameSpace {
    @NotNull
    public static final NameSpace INSTANCE = new NameSpace();
    @NotNull
    public static final String version = "2.19.1";
    @NotNull
    private static final Map<String, Map<String, String>> nameSpaceToIifToIp = new HashMap();

    private NameSpace() {
    }

    public final void add(@NotNull String nameSpace) {
        Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "netns", "add", nameSpace};
        Executor.Companion.run(stringArray);
    }

    public final void delete(@NotNull String nameSpace) {
        Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip", "netns", "del", nameSpace};
        Executor.Companion.run(stringArray);
    }

    public final void dhcpStart(@NotNull String nameSpace, @NotNull String id, @NotNull String interfaceName) {
        Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
        Intrinsics.checkNotNullParameter((Object)id, (String)"id");
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        this.dhcpStop(nameSpace, id, interfaceName);
        String dhcpPidFile = "/var/run/dhclient-" + id + ".pid";
        String[] stringArray = new String[]{"/sbin/dhclient", "-pf", dhcpPidFile, interfaceName};
        this.run(nameSpace, stringArray);
    }

    public final void dhcpStop(@NotNull String nameSpace, @NotNull String id, @NotNull String interfaceName) {
        String dhcpPidFile;
        Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
        Intrinsics.checkNotNullParameter((Object)id, (String)"id");
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (Common.INSTANCE.getOS_LINUX()) {
            dhcpPidFile = "/var/run/dhclient-" + id + ".pid";
            String[] stringArray = new String[]{"/sbin/dhclient", "-r -pf", dhcpPidFile, interfaceName};
            this.run(nameSpace, stringArray);
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

    @NotNull
    public final String run(@NotNull String nameSpace, String ... args) {
        Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
        Intrinsics.checkNotNullParameter((Object)args, (String)"args");
        if (Common.INSTANCE.getOS_LINUX()) {
            List command = new ArrayList();
            command.add("/sbin/ip");
            command.add("netns");
            command.add("exec");
            command.add(nameSpace);
            command.addAll(CollectionsKt.listOf((Object[])Arrays.copyOf(args, args.length)));
            return Executor.Companion.run((Iterable)command);
        }
        throw new RuntimeException("NOT IMPL.");
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final String getIpFromIf(@NotNull String nameSpace, @NotNull String interfaceName, boolean isOnClientConnect) {
        Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        if (Common.INSTANCE.getOS_LINUX()) {
            if (isOnClientConnect) {
                String str;
                String[] stringArray = new String[]{"/sbin/ifconfig", interfaceName};
                String ifaceInfo = this.run(nameSpace, stringArray);
                int index = StringsKt.indexOf$default((CharSequence)ifaceInfo, (String)(str = "inet addr:"), (int)0, (boolean)false, (int)6, null);
                if (index > -1) {
                    String string = ifaceInfo.substring(index += str.length(), StringsKt.indexOf$default((CharSequence)ifaceInfo, (String)" ", (int)index, (boolean)false, (int)4, null));
                    Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                    String possibleAddr = string;
                    Common.INSTANCE.getLogger$NetworkUtils().debug("Found on '{}' possible addr '{}' : ADD", (Object)interfaceName, (Object)possibleAddr);
                    Map<String, Map<String, String>> map = nameSpaceToIifToIp;
                    synchronized (map) {
                        boolean bl = false;
                        Map ifToIp = nameSpaceToIifToIp.get(nameSpace);
                        if (ifToIp == null) {
                            ifToIp = new HashMap();
                            nameSpaceToIifToIp.put(nameSpace, ifToIp);
                        }
                        String string2 = ifToIp.put((String)interfaceName, (String)possibleAddr);
                    }
                    return possibleAddr;
                }
            } else {
                String possibleAddr = null;
                possibleAddr = "";
                Map<String, Map<String, String>> map = nameSpaceToIifToIp;
                synchronized (map) {
                    boolean bl = false;
                    Map<String, String> ifToIp = nameSpaceToIifToIp.get(nameSpace);
                    if (ifToIp != null) {
                        possibleAddr = ifToIp.remove(interfaceName);
                    }
                    Unit unit = Unit.INSTANCE;
                }
                Common.INSTANCE.getLogger$NetworkUtils().debug("Found on '{}' possible addr '{}' : REMOVE", (Object)interfaceName, (Object)possibleAddr);
                if (possibleAddr != null) {
                    return possibleAddr;
                }
            }
            return "";
        }
        throw new RuntimeException("NOT IMPL.");
    }

    public final void addLoopback(@NotNull String nameSpace) {
        Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ip link set dev lo up"};
        this.run(nameSpace, stringArray);
        stringArray = new String[]{"/sbin/ip addr add 127.0.0.1 dev lo"};
        this.run(nameSpace, stringArray);
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0018\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0006\u00a8\u0006\u0007"}, d2={"Ldorkbox/netUtil/NameSpace$Route;", "", "()V", "flush", "", "nameSpace", "", "NetworkUtils"})
    public static final class Route {
        @NotNull
        public static final Route INSTANCE = new Route();

        private Route() {
        }

        public final void flush(@NotNull String nameSpace) {
            Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
            if (!Common.INSTANCE.getOS_LINUX()) {
                throw new RuntimeException("NOT IMPL.");
            }
            String[] stringArray = new String[]{"/sbin/ip", "route", "flush", "cache"};
            INSTANCE.run(nameSpace, stringArray);
        }
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0003\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u0001\u0003B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0004"}, d2={"Ldorkbox/netUtil/NameSpace$Dhcp;", "", "()V", "Dhcp", "NetworkUtils"})
    public static final class dorkbox.netUtil.NameSpace$Dhcp {
        @NotNull
        public static final dorkbox.netUtil.NameSpace$Dhcp INSTANCE = new dorkbox.netUtil.NameSpace$Dhcp();

        private dorkbox.netUtil.NameSpace$Dhcp() {
        }

        @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0004\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001e\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00062\u0006\u0010\b\u001a\u00020\u0006J\u001e\u0010\t\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00062\u0006\u0010\b\u001a\u00020\u0006\u00a8\u0006\n"}, d2={"Ldorkbox/netUtil/NameSpace$Dhcp$Dhcp;", "", "()V", "start", "", "nameSpace", "", "id", "interfaceName", "stop", "NetworkUtils"})
        public static final class Dhcp {
            @NotNull
            public static final Dhcp INSTANCE = new Dhcp();

            private Dhcp() {
            }

            public final void start(@NotNull String nameSpace, @NotNull String id, @NotNull String interfaceName) {
                Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
                Intrinsics.checkNotNullParameter((Object)id, (String)"id");
                Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
                if (!Common.INSTANCE.getOS_LINUX()) {
                    throw new RuntimeException("NOT IMPL.");
                }
                this.stop(nameSpace, id, interfaceName);
                String dhcpPidFile = "/var/run/dhclient-" + id + ".pid";
                String[] stringArray = new String[]{"/sbin/dhclient", "-pf", dhcpPidFile, interfaceName};
                NameSpace.INSTANCE.run(nameSpace, stringArray);
            }

            public final void stop(@NotNull String nameSpace, @NotNull String id, @NotNull String interfaceName) {
                String dhcpPidFile;
                Intrinsics.checkNotNullParameter((Object)nameSpace, (String)"nameSpace");
                Intrinsics.checkNotNullParameter((Object)id, (String)"id");
                Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
                if (Common.INSTANCE.getOS_LINUX()) {
                    dhcpPidFile = "/var/run/dhclient-" + id + ".pid";
                    String[] stringArray = new String[]{"/sbin/dhclient", "-r -pf", dhcpPidFile, interfaceName};
                    NameSpace.INSTANCE.run(nameSpace, stringArray);
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
    }
}

