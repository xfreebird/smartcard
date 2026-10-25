/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.executor.Executor
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.UByte
 *  kotlin.Unit
 *  kotlin.collections.IntIterator
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.ranges.IntRange
 *  kotlin.text.CharsKt
 *  kotlin.text.Regex
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 */
package dorkbox.netUtil;

import dorkbox.executor.Executor;
import dorkbox.netUtil.Common;
import dorkbox.netUtil.Mac;
import java.io.File;
import java.io.Writer;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Locale;
import java.util.Random;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.UByte;
import kotlin.Unit;
import kotlin.collections.IntIterator;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.internal.Intrinsics;
import kotlin.ranges.IntRange;
import kotlin.text.CharsKt;
import kotlin.text.Regex;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000v\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010#\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0002\b\u000b\n\u0002\u0010\u0011\n\u0000\n\u0002\u0010\u001c\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0012\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0010\t\n\u0002\b\b\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u0001>B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0016\u0010\u0017\u001a\u00020\u00182\u0006\u0010\u0019\u001a\u00020\u00102\u0006\u0010\u001a\u001a\u00020\u0010J\u0006\u0010\u001b\u001a\u00020\u0010J\u0006\u0010\u001c\u001a\u00020\u0010J\u0006\u0010\u001d\u001a\u00020\u0010J\u0006\u0010\u001e\u001a\u00020\u0010J\u0006\u0010\u001f\u001a\u00020\u0010J\u000e\u0010 \u001a\u00020\u00102\u0006\u0010!\u001a\u00020\u0010J\u001f\u0010\"\u001a\u00020\u00182\u0012\u0010#\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00100$\"\u00020\u0010\u00a2\u0006\u0002\u0010%J\u000e\u0010\"\u001a\u00020\u00182\u0006\u0010\u001d\u001a\u00020\u0010J\u0014\u0010\"\u001a\u00020\u00182\f\u0010#\u001a\b\u0012\u0004\u0012\u00020\u00100&J\u001a\u0010'\u001a\u00020\u00102\u0006\u0010(\u001a\u00020\u00102\n\b\u0002\u0010)\u001a\u0004\u0018\u00010*J\u001c\u0010+\u001a\u0004\u0018\u00010,2\u0006\u0010(\u001a\u00020\u00102\n\b\u0002\u0010)\u001a\u0004\u0018\u00010*J\u0010\u0010-\u001a\u0004\u0018\u00010.2\u0006\u0010/\u001a\u00020\u0010J\u000e\u00100\u001a\u0002012\u0006\u0010/\u001a\u00020\u0010J\u0010\u00102\u001a\u00020,2\u0006\u00103\u001a\u000204H\u0002J\u000e\u00102\u001a\u00020,2\u0006\u00105\u001a\u00020\u0010J\u000e\u00106\u001a\u0002042\u0006\u00105\u001a\u00020,J\u000e\u00106\u001a\u0002042\u0006\u00105\u001a\u00020\u0010J\u001a\u00106\u001a\u0002042\u0006\u00105\u001a\u00020\u00102\n\b\u0002\u00107\u001a\u0004\u0018\u00010.J\u000e\u00108\u001a\u0002042\u0006\u0010/\u001a\u00020\u0010J\u000e\u00109\u001a\u00020\u00102\u0006\u00105\u001a\u00020,J\u000e\u00109\u001a\u00020\u00102\u0006\u00105\u001a\u000204J\u000e\u0010:\u001a\u00020\u00102\u0006\u00105\u001a\u00020,J\u0016\u0010;\u001a\u00020\u00182\u0006\u00105\u001a\u0002042\u0006\u0010<\u001a\u00020=R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082T\u00a2\u0006\u0002\n\u0000R#\u0010\u0007\u001a\n \t*\u0004\u0018\u00010\b0\b8BX\u0082\u0084\u0002\u00a2\u0006\f\n\u0004\b\f\u0010\r\u001a\u0004\b\n\u0010\u000bR\u0014\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u00100\u000fX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0011\u001a\u00020\u00108BX\u0082\u0004\u00a2\u0006\u0006\u001a\u0004\b\u0012\u0010\u0013R\u000e\u0010\u0014\u001a\u00020\u0015X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0016\u001a\u00020\u0010X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006?"}, d2={"Ldorkbox/netUtil/Mac;", "", "()V", "COLON_REGEX", "Lkotlin/text/Regex;", "MAC_ADDRESS_LENGTH", "", "MAC_ADDRESS_PATTERN", "Ljava/util/regex/Pattern;", "kotlin.jvm.PlatformType", "getMAC_ADDRESS_PATTERN", "()Ljava/util/regex/Pattern;", "MAC_ADDRESS_PATTERN$delegate", "Lkotlin/Lazy;", "fakeMacsInUse", "", "", "randHex", "getRandHex", "()Ljava/lang/String;", "random", "Ljava/util/Random;", "version", "assign", "", "interfaceName", "macAddress", "fakeDockerMac", "fakeDockerMacUnsafe", "fakeMac", "fakeVpnMac", "fakeVpnMacUnsafe", "fakeVpnMacWithDir", "vpnKeyDirForExistingVpnMacs", "freeFakeMac", "fakeMacs", "", "([Ljava/lang/String;)V", "", "getMacAddress", "ip", "logger", "Lorg/slf4j/Logger;", "getMacAddressByte", "", "getMacDelimiter", "Ldorkbox/netUtil/Mac$MacDelimiter;", "macAsString", "isValid", "", "toBytes", "x", "", "mac", "toLong", "delimiter", "toLongSafe", "toStringLowerCase", "toStringUpperCase", "writeStringLowerCase", "writer", "Ljava/io/Writer;", "MacDelimiter", "NetworkUtils"})
public final class Mac {
    @NotNull
    public static final Mac INSTANCE = new Mac();
    @NotNull
    public static final String version = "2.19.1";
    private static final int MAC_ADDRESS_LENGTH = 6;
    @NotNull
    private static final Random random = new Random();
    @NotNull
    private static final Set<String> fakeMacsInUse = new HashSet();
    @NotNull
    private static final Lazy MAC_ADDRESS_PATTERN$delegate = LazyKt.lazy((Function0)MAC_ADDRESS_PATTERN.2.INSTANCE);
    @NotNull
    private static final Regex COLON_REGEX = new Regex(":");

    private Mac() {
    }

    private final Pattern getMAC_ADDRESS_PATTERN() {
        Lazy lazy = MAC_ADDRESS_PATTERN$delegate;
        return (Pattern)lazy.getValue();
    }

    @NotNull
    public final String getMacAddress(@NotNull String ip, @Nullable Logger logger) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        try {
            byte[] mac = this.getMacAddressByte(ip, logger);
            if (mac == null) {
                Logger logger2 = logger;
                if (logger2 != null) {
                    logger2.error("Unable to get MAC address for IP '{}'", (Object)ip);
                }
                return "";
            }
            StringBuilder s = new StringBuilder(18);
            for (byte b : mac) {
                if (((CharSequence)s).length() > 0) {
                    s.append(':');
                }
                String string = "%02x";
                Object[] objectArray = new Object[]{b};
                String string2 = String.format(string, Arrays.copyOf(objectArray, objectArray.length));
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"format(format, *args)");
                s.append(string2);
            }
            String string = s.toString();
            Intrinsics.checkNotNullExpressionValue((Object)string, (String)"s.toString()");
            return string;
        }
        catch (Exception e) {
            block8: {
                if (logger != null) {
                    logger.error("Unable to get MAC address for IP '{}'", (Object)ip, (Object)e);
                } else {
                    e.printStackTrace();
                }
                Logger logger3 = logger;
                if (logger3 == null) break block8;
                logger3.error("Unable to get MAC address for IP '{}'", (Object)ip);
            }
            return "";
        }
    }

    public static /* synthetic */ String getMacAddress$default(Mac mac, String string, Logger logger, int n, Object object) {
        if ((n & 2) != 0) {
            logger = null;
        }
        return mac.getMacAddress(string, logger);
    }

    @Nullable
    public final byte[] getMacAddressByte(@NotNull String ip, @Nullable Logger logger) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        try {
            InetAddress addr = InetAddress.getByName(ip);
            NetworkInterface networkInterface = NetworkInterface.getByInetAddress(addr);
            if (networkInterface == null) {
                Logger logger2 = logger;
                if (logger2 != null) {
                    logger2.error("Unable to get MAC address for IP '{}'", (Object)ip);
                }
                return null;
            }
            byte[] mac = networkInterface.getHardwareAddress();
            if (mac == null) {
                Logger logger3 = logger;
                if (logger3 != null) {
                    logger3.error("Unable to get MAC address for IP '{}'", (Object)ip);
                }
                return null;
            }
            return mac;
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to get MAC address for IP '{}'", (Object)ip, (Object)e);
            } else {
                e.printStackTrace();
            }
            return null;
        }
    }

    public static /* synthetic */ byte[] getMacAddressByte$default(Mac mac, String string, Logger logger, int n, Object object) {
        if ((n & 2) != 0) {
            logger = null;
        }
        return mac.getMacAddressByte(string, logger);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void freeFakeMac(@NotNull String fakeMac) {
        Intrinsics.checkNotNullParameter((Object)fakeMac, (String)"fakeMac");
        Set<String> set = fakeMacsInUse;
        synchronized (set) {
            boolean bl = false;
            boolean bl2 = fakeMacsInUse.remove(fakeMac);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void freeFakeMac(String ... fakeMacs) {
        Intrinsics.checkNotNullParameter((Object)fakeMacs, (String)"fakeMacs");
        Set<String> set = fakeMacsInUse;
        synchronized (set) {
            boolean bl = false;
            String[] $this$forEach$iv = fakeMacs;
            boolean $i$f$forEach = false;
            int n = $this$forEach$iv.length;
            for (int i = 0; i < n; ++i) {
                String element$iv;
                String it = element$iv = $this$forEach$iv[i];
                boolean bl2 = false;
                fakeMacsInUse.remove(it);
            }
            Unit unit = Unit.INSTANCE;
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void freeFakeMac(@NotNull Iterable<String> fakeMacs) {
        Intrinsics.checkNotNullParameter(fakeMacs, (String)"fakeMacs");
        Set<String> set = fakeMacsInUse;
        synchronized (set) {
            boolean bl = false;
            Iterable<String> $this$forEach$iv = fakeMacs;
            boolean $i$f$forEach = false;
            Iterator<String> iterator = $this$forEach$iv.iterator();
            while (iterator.hasNext()) {
                String element$iv;
                String it = element$iv = iterator.next();
                boolean bl2 = false;
                fakeMacsInUse.remove(it);
            }
            Unit unit = Unit.INSTANCE;
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     * WARNING - void declaration
     */
    @NotNull
    public final String fakeMac() {
        Set<String> set = fakeMacsInUse;
        synchronized (set) {
            void var3_4;
            boolean bl = false;
            String mac = INSTANCE.fakeVpnMacUnsafe();
            while (fakeMacsInUse.contains(mac)) {
                mac = INSTANCE.fakeVpnMacUnsafe();
            }
            fakeMacsInUse.add(mac);
            void var4_5 = var3_4;
            return var4_5;
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     * WARNING - void declaration
     */
    @NotNull
    public final String fakeDockerMac() {
        Set<String> set = fakeMacsInUse;
        synchronized (set) {
            void var3_4;
            boolean bl = false;
            String mac = INSTANCE.fakeDockerMacUnsafe();
            while (fakeMacsInUse.contains(mac)) {
                mac = INSTANCE.fakeDockerMacUnsafe();
            }
            fakeMacsInUse.add(mac);
            void var4_5 = var3_4;
            return var4_5;
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final String fakeVpnMac() {
        String mac = null;
        mac = this.fakeVpnMacUnsafe();
        Set<String> set = fakeMacsInUse;
        synchronized (set) {
            boolean bl = false;
            while (fakeMacsInUse.contains(mac)) {
                mac = INSTANCE.fakeVpnMacUnsafe();
            }
            boolean bl2 = fakeMacsInUse.add(mac);
        }
        return mac;
    }

    @NotNull
    public final String fakeVpnMacUnsafe() {
        String vpnID = this.getRandHex();
        while (Intrinsics.areEqual((Object)vpnID, (Object)"d0")) {
            vpnID = this.getRandHex();
        }
        return "02:" + vpnID + ':' + this.getRandHex() + ':' + this.getRandHex() + ':' + this.getRandHex() + ':' + this.getRandHex();
    }

    @NotNull
    public final String fakeDockerMacUnsafe() {
        return "02:d0:" + this.getRandHex() + ':' + this.getRandHex() + ':' + this.getRandHex() + ':' + this.getRandHex();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final String fakeVpnMacWithDir(@NotNull String vpnKeyDirForExistingVpnMacs) {
        Intrinsics.checkNotNullParameter((Object)vpnKeyDirForExistingVpnMacs, (String)"vpnKeyDirForExistingVpnMacs");
        Set<String> set = fakeMacsInUse;
        synchronized (set) {
            boolean bl = false;
            String mac = INSTANCE.fakeVpnMacUnsafe();
            while (fakeMacsInUse.contains(mac) || new File(vpnKeyDirForExistingVpnMacs, mac + ".crt").exists()) {
                mac = INSTANCE.fakeVpnMacUnsafe();
            }
            fakeMacsInUse.add(mac);
            String string = mac;
            return string;
        }
    }

    private final String getRandHex() {
        String string;
        int i = random.nextInt(255);
        if (i < 16) {
            string = '0' + Integer.toHexString(i);
        } else {
            String string2 = Integer.toHexString(i);
            string = string2;
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"{\n                Intege\u2026exString(i)\n            }");
        }
        return string;
    }

    @NotNull
    public final String toStringLowerCase(long mac) {
        byte[] macBytes = this.toBytes(mac);
        StringBuilder buf = new StringBuilder();
        Iterable $this$forEach$iv = (Iterable)new IntRange(2, 7);
        boolean $i$f$forEach = false;
        Iterator iterator = $this$forEach$iv.iterator();
        while (iterator.hasNext()) {
            byte by;
            int element$iv;
            int index = element$iv = ((IntIterator)iterator).nextInt();
            boolean bl = false;
            byte by2 = macBytes[index];
            if (((CharSequence)buf).length() > 0) {
                buf.append(':');
            }
            boolean bl2 = 0 <= (by = by2) ? by < 16 : false;
            if (bl2) {
                buf.append('0');
            }
            buf.append(Integer.toHexString(UByte.constructor-impl((byte)by2) & 0xFF));
        }
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    public final void writeStringLowerCase(long mac, @NotNull Writer writer) throws Exception {
        Intrinsics.checkNotNullParameter((Object)writer, (String)"writer");
        byte[] macBytes = this.toBytes(mac);
        int bytesWritten = 0;
        Iterable $this$forEach$iv = (Iterable)new IntRange(2, 7);
        boolean $i$f$forEach = false;
        Iterator iterator = $this$forEach$iv.iterator();
        while (iterator.hasNext()) {
            byte by;
            int element$iv;
            int index = element$iv = ((IntIterator)iterator).nextInt();
            boolean bl = false;
            byte by2 = macBytes[index];
            if (bytesWritten != 0) {
                writer.write(":");
                ++bytesWritten;
            }
            boolean bl2 = 0 <= (by = by2) ? by < 16 : false;
            if (bl2) {
                writer.append('0');
            }
            writer.write(Integer.toHexString(by2 & 0xFF));
            bytesWritten += 2;
        }
    }

    private final byte[] toBytes(long x) {
        byte[] byArray = new byte[]{(byte)(x >> 56), (byte)(x >> 48), (byte)(x >> 40), (byte)(x >> 32), (byte)(x >> 24), (byte)(x >> 16), (byte)(x >> 8), (byte)(x >> 0)};
        return byArray;
    }

    @NotNull
    public final String toStringLowerCase(@NotNull byte[] mac) {
        Intrinsics.checkNotNullParameter((Object)mac, (String)"mac");
        StringBuilder buf = new StringBuilder();
        for (int n : mac) {
            int n2;
            if (((CharSequence)buf).length() > 0) {
                buf.append(':');
            }
            boolean bl = 0 <= (n2 = n) ? n2 < 16 : false;
            if (bl) {
                buf.append('0');
            }
            buf.append(Integer.toHexString(n < 0 ? n + 256 : n));
        }
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    @NotNull
    public final String toStringUpperCase(@NotNull byte[] mac) {
        Intrinsics.checkNotNullParameter((Object)mac, (String)"mac");
        StringBuilder buf = new StringBuilder();
        for (byte b : mac) {
            String string;
            byte by;
            if (((CharSequence)buf).length() > 0) {
                buf.append(':');
            }
            boolean bl = 0 <= (by = b) ? by < 16 : false;
            if (bl) {
                buf.append('0');
            }
            Intrinsics.checkNotNullExpressionValue((Object)Integer.toHexString(b & 0xFF), (String)"toHexString(b.toInt() and 0xFF)");
            Locale locale = Locale.ENGLISH;
            Intrinsics.checkNotNullExpressionValue((Object)locale, (String)"ENGLISH");
            String string2 = string.toUpperCase(locale);
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).toUpperCase(locale)");
            buf.append(string2);
        }
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    @NotNull
    public final byte[] toBytes(@NotNull String mac) {
        Intrinsics.checkNotNullParameter((Object)mac, (String)"mac");
        CharSequence charSequence = mac;
        Regex regex = COLON_REGEX;
        String string = "";
        String s = regex.replace(charSequence, string);
        byte[] byArray = new BigInteger(s, 16).toByteArray();
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"BigInteger(s, 16).toByteArray()");
        return byArray;
    }

    public final long toLongSafe(@NotNull String macAsString) {
        Intrinsics.checkNotNullParameter((Object)macAsString, (String)"macAsString");
        return this.toLong(macAsString, this.getMacDelimiter(macAsString));
    }

    public final long toLong(@NotNull String mac) {
        Intrinsics.checkNotNullParameter((Object)mac, (String)"mac");
        return this.toLong(mac, MacDelimiter.COLON);
    }

    public final long toLong(@NotNull byte[] mac) {
        Intrinsics.checkNotNullParameter((Object)mac, (String)"mac");
        return ((long)mac[5] & 0xFFL) + (((long)mac[4] & 0xFFL) << 8) + (((long)mac[3] & 0xFFL) << 16) + (((long)mac[2] & 0xFFL) << 24) + (((long)mac[1] & 0xFFL) << 32) + (((long)mac[0] & 0xFFL) << 40);
    }

    /*
     * WARNING - void declaration
     */
    public final long toLong(@NotNull String mac, @Nullable MacDelimiter delimiter) {
        Intrinsics.checkNotNullParameter((Object)mac, (String)"mac");
        byte[] addressInBytes = new byte[6];
        try {
            String[] elements = null;
            if (delimiter != null) {
                void $this$toTypedArray$iv;
                Object object = mac;
                Regex regex = delimiter.getRegex();
                int n = 0;
                object = regex.split((CharSequence)object, n);
                boolean $i$f$toTypedArray = false;
                void thisCollection$iv = $this$toTypedArray$iv;
                String[] stringArray = thisCollection$iv.toArray(new String[0]);
                Intrinsics.checkNotNull((Object)stringArray, (String)"null cannot be cast to non-null type kotlin.Array<T of kotlin.collections.ArraysKt__ArraysJVMKt.toTypedArray>");
                elements = stringArray;
            } else {
                elements = new String[6];
                int index = 0;
                int substringPos = 0;
                while (index < 6) {
                    Intrinsics.checkNotNullExpressionValue((Object)mac.substring(substringPos, substringPos + 2), (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                    ++index;
                    substringPos += 2;
                }
            }
            for (int i = 0; i < 6; ++i) {
                String element;
                String string = element = elements[i];
                Intrinsics.checkNotNull((Object)string);
                addressInBytes[i] = (byte)Integer.parseInt(string, CharsKt.checkRadix((int)16));
            }
        }
        catch (Exception e) {
            Common.INSTANCE.getLogger$NetworkUtils().error("Error parsing MAC address '{}'", (Object)mac, (Object)e);
        }
        return this.toLong(addressInBytes);
    }

    public static /* synthetic */ long toLong$default(Mac mac, String string, MacDelimiter macDelimiter, int n, Object object) {
        if ((n & 2) != 0) {
            macDelimiter = MacDelimiter.COLON;
        }
        return mac.toLong(string, macDelimiter);
    }

    public final boolean isValid(@NotNull String macAsString) {
        Intrinsics.checkNotNullParameter((Object)macAsString, (String)"macAsString");
        if (((CharSequence)macAsString).length() == 0) {
            return false;
        }
        String normalizedMac = macAsString;
        CharSequence charSequence = normalizedMac;
        Regex regex = COLON_REGEX;
        int n = 0;
        Collection $this$toTypedArray$iv = regex.split(charSequence, n);
        boolean $i$f$toTypedArray = false;
        Collection thisCollection$iv = $this$toTypedArray$iv;
        String[] stringArray = thisCollection$iv.toArray(new String[0]);
        Intrinsics.checkNotNull((Object)stringArray, (String)"null cannot be cast to non-null type kotlin.Array<T of kotlin.collections.ArraysKt__ArraysJVMKt.toTypedArray>");
        if (stringArray.length != 6) {
            if (StringsKt.contains$default((CharSequence)normalizedMac, (CharSequence)".", (boolean)false, (int)2, null)) {
                normalizedMac = StringsKt.replace$default((String)normalizedMac, (String)".", (String)":", (boolean)false, (int)4, null);
            } else if (StringsKt.contains$default((CharSequence)normalizedMac, (CharSequence)" ", (boolean)false, (int)2, null)) {
                normalizedMac = StringsKt.replace$default((String)normalizedMac, (String)" ", (String)":", (boolean)false, (int)4, null);
            } else {
                normalizedMac = "";
                int index = 0;
                int substringPos = 0;
                while (index < 6 && macAsString.length() >= substringPos + 2) {
                    String string;
                    if (index != 5) {
                        StringBuilder stringBuilder = new StringBuilder().append(normalizedMac);
                        String string2 = macAsString.substring(substringPos, substringPos + 2);
                        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                        string = stringBuilder.append(string2).append(':').toString();
                    } else {
                        StringBuilder stringBuilder = new StringBuilder().append(normalizedMac);
                        String string3 = macAsString.substring(substringPos, substringPos + 2);
                        Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                        string = stringBuilder.append(string3).toString();
                    }
                    normalizedMac = string;
                    ++index;
                    substringPos += 2;
                }
            }
        }
        Matcher matcher = this.getMAC_ADDRESS_PATTERN().matcher(normalizedMac);
        return matcher.matches();
    }

    @Nullable
    public final MacDelimiter getMacDelimiter(@NotNull String macAsString) {
        Intrinsics.checkNotNullParameter((Object)macAsString, (String)"macAsString");
        return StringsKt.contains$default((CharSequence)macAsString, (CharSequence)":", (boolean)false, (int)2, null) ? MacDelimiter.COLON : (StringsKt.contains$default((CharSequence)macAsString, (CharSequence)".", (boolean)false, (int)2, null) ? MacDelimiter.PERIOD : (StringsKt.contains$default((CharSequence)macAsString, (CharSequence)" ", (boolean)false, (int)2, null) ? MacDelimiter.SPACE : MacDelimiter.COLON));
    }

    public final void assign(@NotNull String interfaceName, @NotNull String macAddress) {
        Intrinsics.checkNotNullParameter((Object)interfaceName, (String)"interfaceName");
        Intrinsics.checkNotNullParameter((Object)macAddress, (String)"macAddress");
        if (!Common.INSTANCE.getOS_LINUX()) {
            throw new RuntimeException("NOT IMPL.");
        }
        String[] stringArray = new String[]{"/sbin/ifconfig", interfaceName, "hw", "ether", macAddress};
        Executor.Companion.run(stringArray);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    static {
        Set<String> set = fakeMacsInUse;
        synchronized (set) {
            boolean bl = false;
            Unit unit = Unit.INSTANCE;
        }
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0006\b\u0086\u0001\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u000f\b\u0002\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006R\u0011\u0010\u0007\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\nj\u0002\b\u000bj\u0002\b\fj\u0002\b\r\u00a8\u0006\u000e"}, d2={"Ldorkbox/netUtil/Mac$MacDelimiter;", "", "delimiter", "", "(Ljava/lang/String;ILjava/lang/String;)V", "getDelimiter", "()Ljava/lang/String;", "regex", "Lkotlin/text/Regex;", "getRegex", "()Lkotlin/text/Regex;", "COLON", "PERIOD", "SPACE", "NetworkUtils"})
    public static final class MacDelimiter
    extends Enum<MacDelimiter> {
        @NotNull
        private final String delimiter;
        @NotNull
        private final Regex regex;
        public static final /* enum */ MacDelimiter COLON = new MacDelimiter(":");
        public static final /* enum */ MacDelimiter PERIOD = new MacDelimiter(".");
        public static final /* enum */ MacDelimiter SPACE = new MacDelimiter(" ");
        private static final /* synthetic */ MacDelimiter[] $VALUES;

        private MacDelimiter(String delimiter) {
            this.delimiter = delimiter;
            this.regex = new Regex(this.delimiter);
        }

        @NotNull
        public final String getDelimiter() {
            return this.delimiter;
        }

        @NotNull
        public final Regex getRegex() {
            return this.regex;
        }

        public static MacDelimiter[] values() {
            return (MacDelimiter[])$VALUES.clone();
        }

        public static MacDelimiter valueOf(String value) {
            return Enum.valueOf(MacDelimiter.class, value);
        }

        static {
            $VALUES = macDelimiterArray = new MacDelimiter[]{MacDelimiter.COLON, MacDelimiter.PERIOD, MacDelimiter.SPACE};
        }
    }
}

