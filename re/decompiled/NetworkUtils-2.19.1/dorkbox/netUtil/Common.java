/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.updates.Updates
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.netUtil;

import dorkbox.updates.Updates;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.security.AccessController;
import java.util.Locale;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000D\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0015\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\f\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u00c0\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0014\u001a\u00020\u00152\u0006\u0010\u0016\u001a\u00020\u0017J\u0016\u0010\u0018\u001a\u00020\u00062\u0006\u0010\u0019\u001a\u00020\u00132\u0006\u0010\u001a\u001a\u00020\u0006J\u0016\u0010\u001b\u001a\u00020\u001c2\u0006\u0010\u001d\u001a\u00020\u001e2\u0006\u0010\u001f\u001a\u00020\u0015J\u0016\u0010\u001b\u001a\u00020\u001c2\u0006\u0010 \u001a\u00020\u00132\u0006\u0010\u001f\u001a\u00020\u0015R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0007\u0010\bR\u0011\u0010\t\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\bR\u0011\u0010\u000b\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\bR\u001c\u0010\r\u001a\n \u000f*\u0004\u0018\u00010\u000e0\u000eX\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u000e\u0010\u0012\u001a\u00020\u0013X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006!"}, d2={"Ldorkbox/netUtil/Common;", "", "()V", "HEX2B", "", "OS_LINUX", "", "getOS_LINUX", "()Z", "OS_MAC", "getOS_MAC", "OS_WINDOWS", "getOS_WINDOWS", "logger", "Lorg/slf4j/Logger;", "kotlin.jvm.PlatformType", "getLogger$NetworkUtils", "()Lorg/slf4j/Logger;", "version", "", "decodeHexNibble", "", "c", "", "getBoolean", "property", "defaultValue", "socketAddress", "Ljava/net/InetSocketAddress;", "host", "Ljava/net/InetAddress;", "port", "hostname", "NetworkUtils"})
public final class Common {
    @NotNull
    public static final Common INSTANCE;
    @NotNull
    public static final String version = "2.19.1";
    private static final boolean OS_LINUX;
    private static final boolean OS_WINDOWS;
    private static final boolean OS_MAC;
    private static final Logger logger;
    @NotNull
    private static final int[] HEX2B;

    private Common() {
    }

    public final boolean getOS_LINUX() {
        return OS_LINUX;
    }

    public final boolean getOS_WINDOWS() {
        return OS_WINDOWS;
    }

    public final boolean getOS_MAC() {
        return OS_MAC;
    }

    public final Logger getLogger$NetworkUtils() {
        return logger;
    }

    public final boolean getBoolean(@NotNull String property, boolean defaultValue) {
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        String string = System.getProperty(property, String.valueOf(defaultValue));
        if (string == null) {
            return defaultValue;
        }
        String value = string;
        String string2 = ((Object)StringsKt.trim((CharSequence)value)).toString();
        Locale locale = Locale.getDefault();
        Intrinsics.checkNotNullExpressionValue((Object)locale, (String)"getDefault()");
        String string3 = string2.toLowerCase(locale);
        Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String).toLowerCase(locale)");
        value = string3;
        if (((CharSequence)value).length() == 0) {
            return defaultValue;
        }
        if (Intrinsics.areEqual((Object)"false", (Object)value) || Intrinsics.areEqual((Object)"no", (Object)value) || Intrinsics.areEqual((Object)"0", (Object)value)) {
            return false;
        }
        return Intrinsics.areEqual((Object)"true", (Object)value) || Intrinsics.areEqual((Object)"yes", (Object)value) || Intrinsics.areEqual((Object)"1", (Object)value) ? true : defaultValue;
    }

    public final int decodeHexNibble(char c) {
        int n;
        char index = c;
        try {
            n = HEX2B[index];
        }
        catch (Exception e) {
            n = -1;
        }
        return n;
    }

    @NotNull
    public final InetSocketAddress socketAddress(@NotNull String hostname, int port) {
        Intrinsics.checkNotNullParameter((Object)hostname, (String)"hostname");
        InetSocketAddress inetSocketAddress = AccessController.doPrivileged(() -> Common.socketAddress$lambda$2(hostname, port));
        Intrinsics.checkNotNullExpressionValue((Object)inetSocketAddress, (String)"doPrivileged(PrivilegedA\u2026ddress(hostname, port) })");
        return inetSocketAddress;
    }

    @NotNull
    public final InetSocketAddress socketAddress(@NotNull InetAddress host, int port) {
        Intrinsics.checkNotNullParameter((Object)host, (String)"host");
        InetSocketAddress inetSocketAddress = AccessController.doPrivileged(() -> Common.socketAddress$lambda$3(host, port));
        Intrinsics.checkNotNullExpressionValue((Object)inetSocketAddress, (String)"doPrivileged(PrivilegedA\u2026ketAddress(host, port) })");
        return inetSocketAddress;
    }

    private static final String _init_$lambda$0() {
        return System.getProperty("os.name", "linux");
    }

    private static final InetSocketAddress socketAddress$lambda$2(String $hostname, int $port) {
        Intrinsics.checkNotNullParameter((Object)$hostname, (String)"$hostname");
        return new InetSocketAddress($hostname, $port);
    }

    private static final InetSocketAddress socketAddress$lambda$3(InetAddress $host, int $port) {
        Intrinsics.checkNotNullParameter((Object)$host, (String)"$host");
        return new InetSocketAddress($host, $port);
    }

    static {
        int[] nArray;
        String string;
        INSTANCE = new Common();
        try {
            string = System.getSecurityManager() == null ? System.getProperty("os.name", "linux") : AccessController.doPrivileged(Common::_init_$lambda$0);
        }
        catch (Exception ignored) {
            string = "linux";
        }
        String string2 = string;
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"try {\n            if (Sy\u2026        \"linux\"\n        }");
        String string3 = string2;
        Locale locale = Locale.getDefault();
        Intrinsics.checkNotNullExpressionValue((Object)locale, (String)"getDefault()");
        String string4 = string3.toLowerCase(locale);
        Intrinsics.checkNotNullExpressionValue((Object)string4, (String)"this as java.lang.String).toLowerCase(locale)");
        String osName = string4;
        if (StringsKt.startsWith$default((String)osName, (String)"mac", (boolean)false, (int)2, null) || StringsKt.startsWith$default((String)osName, (String)"darwin", (boolean)false, (int)2, null)) {
            OS_LINUX = false;
            OS_WINDOWS = false;
            OS_MAC = true;
        } else if (StringsKt.startsWith$default((String)osName, (String)"win", (boolean)false, (int)2, null)) {
            OS_LINUX = false;
            OS_WINDOWS = true;
            OS_MAC = false;
        } else {
            OS_LINUX = true;
            OS_WINDOWS = false;
            OS_MAC = false;
        }
        Updates.INSTANCE.add(Common.class, "956b308f207944af95928ef6282a46d7", version);
        logger = LoggerFactory.getLogger((String)"NetworkUtils");
        int[] $this$HEX2B_u24lambda_u241 = nArray = new int[103];
        boolean bl = false;
        $this$HEX2B_u24lambda_u241[48] = 0;
        $this$HEX2B_u24lambda_u241[49] = 1;
        $this$HEX2B_u24lambda_u241[50] = 2;
        $this$HEX2B_u24lambda_u241[51] = 3;
        $this$HEX2B_u24lambda_u241[52] = 4;
        $this$HEX2B_u24lambda_u241[53] = 5;
        $this$HEX2B_u24lambda_u241[54] = 6;
        $this$HEX2B_u24lambda_u241[55] = 7;
        $this$HEX2B_u24lambda_u241[56] = 8;
        $this$HEX2B_u24lambda_u241[57] = 9;
        $this$HEX2B_u24lambda_u241[65] = 10;
        $this$HEX2B_u24lambda_u241[66] = 11;
        $this$HEX2B_u24lambda_u241[67] = 12;
        $this$HEX2B_u24lambda_u241[68] = 13;
        $this$HEX2B_u24lambda_u241[69] = 14;
        $this$HEX2B_u24lambda_u241[70] = 15;
        $this$HEX2B_u24lambda_u241[97] = 10;
        $this$HEX2B_u24lambda_u241[98] = 11;
        $this$HEX2B_u24lambda_u241[99] = 12;
        $this$HEX2B_u24lambda_u241[100] = 13;
        $this$HEX2B_u24lambda_u241[101] = 14;
        $this$HEX2B_u24lambda_u241[102] = 15;
        HEX2B = nArray;
    }
}

