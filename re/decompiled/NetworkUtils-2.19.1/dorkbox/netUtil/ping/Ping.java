/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.executor.Executor
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.netUtil.ping;

import dorkbox.executor.Executor;
import dorkbox.netUtil.Common;
import dorkbox.netUtil.IP;
import dorkbox.netUtil.ping.PingResult;
import dorkbox.netUtil.ping.PingResultBuilder;
import java.io.IOException;
import java.net.InetAddress;
import java.time.Duration;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000D\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\n\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0012\n\u0000\n\u0002\u0018\u0002\n\u0000\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0003\u001a\u00020\u00002\u0006\u0010\u0003\u001a\u00020\u0004J\u000e\u0010\u0005\u001a\u00020\u00002\u0006\u0010\u0012\u001a\u00020\u0004J\u000e\u0010\u0007\u001a\u00020\u00002\u0006\u0010\u0013\u001a\u00020\u0014J\u000e\u0010\u0007\u001a\u00020\u00002\u0006\u0010\u0015\u001a\u00020\u0016J\u000e\u0010\u0007\u001a\u00020\u00002\u0006\u0010\u0007\u001a\u00020\bJ\u0010\u0010\u0017\u001a\u00020\u00182\b\b\u0002\u0010\u0007\u001a\u00020\bJ\u000e\u0010\f\u001a\u00020\u00002\u0006\u0010\f\u001a\u00020\u0004J\u000e\u0010\u0010\u001a\u00020\u00002\u0006\u0010\u0012\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0005\u001a\u0004\u0018\u00010\u0004X\u0082\u000e\u00a2\u0006\u0004\n\u0002\u0010\u0006R\u000e\u0010\u0007\u001a\u00020\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0016\u0010\t\u001a\n \u000b*\u0004\u0018\u00010\n0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0012\u0010\f\u001a\u0004\u0018\u00010\rX\u0082\u000e\u00a2\u0006\u0004\n\u0002\u0010\u000eR\u000e\u0010\u000f\u001a\u00020\bX\u0086T\u00a2\u0006\u0002\n\u0000R\u0016\u0010\u0010\u001a\n \u000b*\u0004\u0018\u00010\u00110\u0011X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0019"}, d2={"Ldorkbox/netUtil/ping/Ping;", "", "()V", "count", "", "deadline", "Ljava/lang/Integer;", "host", "", "logger", "Lorg/slf4j/Logger;", "kotlin.jvm.PlatformType", "ttl", "", "Ljava/lang/Short;", "version", "waitTime", "Ljava/time/Duration;", "seconds", "ipAddress", "Ljava/net/InetAddress;", "ipAddressBytes", "", "run", "Ldorkbox/netUtil/ping/PingResult;", "NetworkUtils"})
public final class Ping {
    @NotNull
    public static final Ping INSTANCE = new Ping();
    private static final Logger logger = LoggerFactory.getLogger((String)Ping.class.getSimpleName());
    @NotNull
    public static final String version = "2.19.1";
    @NotNull
    private static String host = "1.1.1.1";
    private static int count = 4;
    private static Duration waitTime = Duration.ofSeconds(4L);
    @Nullable
    private static Integer deadline;
    @Nullable
    private static Short ttl;

    private Ping() {
    }

    @NotNull
    public final Ping host(@NotNull String host) {
        Intrinsics.checkNotNullParameter((Object)host, (String)"host");
        Ping.host = host;
        return this;
    }

    @NotNull
    public final Ping host(@NotNull InetAddress ipAddress) {
        Intrinsics.checkNotNullParameter((Object)ipAddress, (String)"ipAddress");
        host = IP.toString$default(IP.INSTANCE, ipAddress, false, 2, null);
        return this;
    }

    @NotNull
    public final Ping host(@NotNull byte[] ipAddressBytes) {
        Intrinsics.checkNotNullParameter((Object)ipAddressBytes, (String)"ipAddressBytes");
        host = IP.toString$default(IP.INSTANCE, ipAddressBytes, 0, 0, 6, null);
        return this;
    }

    @NotNull
    public final Ping count(int count) {
        Ping.count = count;
        return this;
    }

    @NotNull
    public final Ping waitTime(int seconds) {
        waitTime = Duration.ofSeconds(seconds);
        return this;
    }

    @NotNull
    public final Ping deadline(int seconds) {
        deadline = seconds;
        return this;
    }

    @NotNull
    public final Ping ttl(int ttl) {
        Ping.ttl = (short)ttl;
        return this;
    }

    @NotNull
    public final PingResult run(@NotNull String host) throws IOException {
        Intrinsics.checkNotNullParameter((Object)host, (String)"host");
        String[] stringArray = new String[]{"ping"};
        Executor ping = new Executor().command(stringArray);
        if (Common.INSTANCE.getOS_WINDOWS()) {
            stringArray = new String[]{"-n " + count};
            ping.addArg(stringArray);
        } else {
            stringArray = new String[]{"-c " + count};
            ping.addArg(stringArray);
        }
        if (waitTime != null) {
            if (Common.INSTANCE.getOS_MAC()) {
                stringArray = new String[]{"-W " + waitTime.toMillis()};
                ping.addArg(stringArray);
            } else if (Common.INSTANCE.getOS_WINDOWS()) {
                stringArray = new String[]{"-w " + waitTime.toMillis()};
                ping.addArg(stringArray);
            } else {
                stringArray = new String[]{"-W " + waitTime.getSeconds()};
                ping.addArg(stringArray);
            }
        }
        if (deadline != null) {
            if (Common.INSTANCE.getOS_MAC()) {
                stringArray = new String[]{"-t " + deadline};
                ping.addArg(stringArray);
            } else if (Common.INSTANCE.getOS_WINDOWS()) {
                logger.info("Deadline is not supported on Windows");
            } else {
                stringArray = new String[]{"-w " + deadline};
                ping.addArg(stringArray);
            }
        }
        if (ttl != null) {
            if (Common.INSTANCE.getOS_MAC()) {
                stringArray = new String[]{"-m " + ttl};
                ping.addArg(stringArray);
            } else if (Common.INSTANCE.getOS_WINDOWS()) {
                stringArray = new String[]{"-i " + ttl};
                ping.addArg(stringArray);
            } else {
                stringArray = new String[]{"-t " + ttl};
                ping.addArg(stringArray);
            }
        }
        stringArray = new String[]{host};
        ping.addArg(stringArray);
        String output = Executor.startAsShellBlocking$default((Executor)ping.enableRead(), (long)0L, null, (int)3, null).getOutput().utf8();
        return PingResultBuilder.INSTANCE.fromOutput(output);
    }

    public static /* synthetic */ PingResult run$default(Ping ping, String string, int n, Object object) throws IOException {
        if ((n & 1) != 0) {
            string = "1.1.1.1";
        }
        return ping.run(string);
    }
}

