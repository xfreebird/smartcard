/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.UInt
 *  kotlin.Unit
 *  kotlin.UnsignedKt
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Regex
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil;

import dorkbox.netUtil.Common;
import dorkbox.netUtil.IPv4;
import dorkbox.netUtil.IPv6;
import java.io.IOException;
import java.io.Writer;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.UInt;
import kotlin.Unit;
import kotlin.UnsignedKt;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Regex;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u008a\u0001\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0015\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0007\n\u0002\u0010\u000b\n\u0002\b\u0004\n\u0002\u0010\b\n\u0002\b\r\n\u0002\u0010\r\n\u0002\b\u0002\n\u0002\u0010\u0012\n\u0002\b\u0003\n\u0002\u0010\u0005\n\u0002\b\u0006\n\u0002\u0018\u0002\n\u0002\b\u000b\n\u0002\u0010\f\n\u0002\b\t\n\u0002\u0010 \n\u0002\b\u000f\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\t\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010&\u001a\u00020\u001e2\u0006\u0010'\u001a\u00020\fJ\u000e\u0010(\u001a\u00020\u001e2\u0006\u0010)\u001a\u00020\u001eJ\u0018\u0010*\u001a\u00020\u001e2\u0006\u0010+\u001a\u00020,2\u0006\u0010-\u001a\u00020\u001eH\u0002J\b\u0010.\u001a\u0004\u0018\u00010/J\u000e\u00100\u001a\u00020\f2\u0006\u00101\u001a\u00020\u001eJ \u00102\u001a\u0002032\u0006\u00104\u001a\u00020,2\u0006\u00105\u001a\u00020\u001e2\u0006\u00106\u001a\u00020\u001eH\u0002J \u00107\u001a\u00020\u001e2\u0006\u00104\u001a\u00020,2\u0006\u00105\u001a\u00020\u001e2\u0006\u00106\u001a\u00020\u001eH\u0002J\u000e\u00108\u001a\u00020\u00192\u0006\u00109\u001a\u00020:J\u001e\u0010;\u001a\u00020\u00192\u0006\u00109\u001a\u00020\u001e2\u0006\u0010<\u001a\u00020\u001e2\u0006\u0010=\u001a\u00020\u001eJ\u001e\u0010;\u001a\u00020\u00192\u0006\u00109\u001a\u00020\f2\u0006\u0010<\u001a\u00020\f2\u0006\u0010=\u001a\u00020\u001eJ\u000e\u0010>\u001a\u00020\u00192\u0006\u0010?\u001a\u00020\u001eJ\u000e\u0010>\u001a\u00020\u00192\u0006\u0010@\u001a\u00020\fJ\u000e\u0010A\u001a\u00020\u00192\u0006\u0010?\u001a\u00020\u001eJ\u000e\u0010A\u001a\u00020\u00192\u0006\u0010@\u001a\u00020\fJ\u000e\u0010B\u001a\u00020\u00192\u0006\u00104\u001a\u00020\fJ\u000e\u0010C\u001a\u00020\u00192\u0006\u0010@\u001a\u00020\fJ\u0015\u0010D\u001a\u00020\u00192\u0006\u0010E\u001a\u00020FH\u0000\u00a2\u0006\u0002\bGJ%\u0010H\u001a\u00020\u00192\u0006\u00104\u001a\u00020\f2\u0006\u00105\u001a\u00020\u001e2\u0006\u0010I\u001a\u00020\u001eH\u0000\u00a2\u0006\u0002\bJJ \u0010K\u001a\u00020\u00192\u0006\u0010L\u001a\u00020,2\u0006\u00105\u001a\u00020\u001e2\u0006\u00106\u001a\u00020\u001eH\u0002J\u0015\u0010M\u001a\u00020\u00192\u0006\u0010E\u001a\u00020FH\u0000\u00a2\u0006\u0002\bNJ\u001c\u0010O\u001a\b\u0012\u0004\u0012\u00020\f0P2\u0006\u0010Q\u001a\u00020\f2\u0006\u0010R\u001a\u00020\fJ\u0016\u0010S\u001a\u00020\u00192\u0006\u0010T\u001a\u00020\f2\u0006\u0010U\u001a\u00020\u001eJ\u0010\u0010V\u001a\u0004\u0018\u00010\u00062\u0006\u00104\u001a\u00020\fJ\u000e\u0010W\u001a\u00020\u00062\u0006\u00104\u001a\u00020\fJ\u000e\u0010X\u001a\u00020/2\u0006\u0010Y\u001a\u00020\u001eJ\u000e\u0010X\u001a\u00020/2\u0006\u00104\u001a\u00020\fJ\u0010\u0010Z\u001a\u0004\u0018\u00010/2\u0006\u00104\u001a\u00020\fJ\u000e\u0010[\u001a\u00020\u001e2\u0006\u0010\\\u001a\u00020/J\u000e\u0010[\u001a\u00020\u001e2\u0006\u0010@\u001a\u00020\fJ\u000e\u0010]\u001a\u00020\u001e2\u0006\u0010@\u001a\u00020\fJ\u000e\u0010^\u001a\u00020\u00042\u0006\u00104\u001a\u00020\fJ\u000e\u0010_\u001a\u00020\f2\u0006\u00104\u001a\u00020\u0006J\u000e\u0010_\u001a\u00020\f2\u0006\u0010\\\u001a\u00020/J\u001a\u0010_\u001a\u00020`2\u0006\u0010\\\u001a\u00020/2\n\u0010a\u001a\u00060bj\u0002`cJ\u000e\u0010_\u001a\u00020\f2\u0006\u0010d\u001a\u00020\u001eJ\u001a\u0010_\u001a\u00020`2\u0006\u0010d\u001a\u00020\u001e2\n\u0010a\u001a\u00060bj\u0002`cJ\u000e\u0010_\u001a\u00020\f2\u0006\u0010e\u001a\u00020\u0004J\u001a\u0010_\u001a\u00020`2\u0006\u0010e\u001a\u00020\u00042\n\u0010a\u001a\u00060bj\u0002`cJ\u000e\u0010_\u001a\u00020\f2\u0006\u0010d\u001a\u00020fJ\u0018\u0010g\u001a\u0004\u0018\u00010:2\u0006\u00109\u001a\u00020\u00062\u0006\u0010h\u001a\u00020\u001eJ\u0016\u0010i\u001a\u00020`2\u0006\u0010d\u001a\u00020\u001e2\u0006\u0010j\u001a\u00020kR\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001b\u0010\u0005\u001a\u00020\u00068FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\t\u0010\n\u001a\u0004\b\u0007\u0010\bR\u001b\u0010\u000b\u001a\u00020\f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u000f\u0010\n\u001a\u0004\b\r\u0010\u000eR\u000e\u0010\u0010\u001a\u00020\u0011X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001b\u0010\u0012\u001a\u00020\u00068FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0014\u0010\n\u001a\u0004\b\u0013\u0010\bR\u001b\u0010\u0015\u001a\u00020\f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0017\u0010\n\u001a\u0004\b\u0016\u0010\u000eR\u001b\u0010\u0018\u001a\u00020\u00198FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001b\u0010\n\u001a\u0004\b\u0018\u0010\u001aR\u0011\u0010\u001c\u001a\u00020\u0019\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u001aR\u0014\u0010\u001d\u001a\u00020\u001eX\u0086D\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001f\u0010 R\u000e\u0010!\u001a\u00020\u001eX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\"\u001a\u00020\u001eX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010#\u001a\u00020\u001eX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010$\u001a\u00020\u001eX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010%\u001a\u00020\fX\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006l"}, d2={"Ldorkbox/netUtil/IPv4;", "", "()V", "CIDR2MASK", "", "LOCALHOST", "Ljava/net/Inet4Address;", "getLOCALHOST", "()Ljava/net/Inet4Address;", "LOCALHOST$delegate", "Lkotlin/Lazy;", "LOCALHOST_STRING", "", "getLOCALHOST_STRING", "()Ljava/lang/String;", "LOCALHOST_STRING$delegate", "SLASH_REGEX", "Lkotlin/text/Regex;", "WILDCARD", "getWILDCARD", "WILDCARD$delegate", "WILDCARD_STRING", "getWILDCARD_STRING", "WILDCARD_STRING$delegate", "isAvailable", "", "()Z", "isAvailable$delegate", "isPreferred", "length", "", "getLength", "()I", "loopback127", "private10", "private172", "private192", "version", "cidrPrefixFromSubnetMask", "mask", "cidrPrefixToSubnetMask", "cidrPrefix", "decimalDigit", "str", "", "pos", "findFreeSubnet24Cidr", "", "getCidrAsNetmask", "cidr", "ipv4WordToByte", "", "ip", "from", "toExclusive", "ipv4WordToInt", "isFamily", "address", "Ljava/net/InetAddress;", "isInRange", "networkAddress", "networkPrefix", "isLoopback", "ipAsInt", "ipAsString", "isSiteLocal", "isValid", "isValidCidr", "isValidIPv4MappedChar", "c", "", "isValidIPv4MappedChar$NetworkUtils", "isValidIpV4Address", "toExcluded", "isValidIpV4Address$NetworkUtils", "isValidIpV4Word", "word", "isValidNumericChar", "isValidNumericChar$NetworkUtils", "range2Cidr", "", "startIp", "endIp", "scanHosts", "startingIp", "numberOfHosts", "toAddress", "toAddressUnsafe", "toBytes", "bytes", "toBytesOrNull", "toInt", "ipBytes", "toIntUnsafe", "toInts", "toString", "", "buf", "Ljava/lang/StringBuilder;", "Lkotlin/text/StringBuilder;", "ipAddress", "ipInts", "", "truncate", "maskLength", "writeString", "writer", "Ljava/io/Writer;", "NetworkUtils"})
public final class IPv4 {
    @NotNull
    public static final IPv4 INSTANCE = new IPv4();
    @NotNull
    public static final String version = "2.19.1";
    private static final boolean isPreferred = Common.INSTANCE.getBoolean("java.net.preferIPv4Stack", false);
    @NotNull
    private static final Lazy isAvailable$delegate = LazyKt.lazy((Function0)isAvailable.2.INSTANCE);
    @NotNull
    private static final Lazy LOCALHOST$delegate = LazyKt.lazy((Function0)LOCALHOST.2.INSTANCE);
    @NotNull
    private static final Lazy LOCALHOST_STRING$delegate = LazyKt.lazy((Function0)LOCALHOST_STRING.2.INSTANCE);
    @NotNull
    private static final Lazy WILDCARD$delegate = LazyKt.lazy((Function0)WILDCARD.2.INSTANCE);
    @NotNull
    private static final Lazy WILDCARD_STRING$delegate = LazyKt.lazy((Function0)WILDCARD_STRING.2.INSTANCE);
    private static final int length = 4;
    @NotNull
    private static final Regex SLASH_REGEX = new Regex("\\.");
    private static final int private10 = INSTANCE.toInt("10.0.0.0");
    private static final int private172 = INSTANCE.toInt("172.16.0.0");
    private static final int private192 = INSTANCE.toInt("192.168.0.0");
    private static final int loopback127 = INSTANCE.toInt("127.0.0.0");
    @NotNull
    private static final int[] CIDR2MASK;

    private IPv4() {
    }

    public final boolean isPreferred() {
        return isPreferred;
    }

    public final boolean isAvailable() {
        Lazy lazy = isAvailable$delegate;
        return (Boolean)lazy.getValue();
    }

    @NotNull
    public final Inet4Address getLOCALHOST() {
        Lazy lazy = LOCALHOST$delegate;
        return (Inet4Address)lazy.getValue();
    }

    @NotNull
    public final String getLOCALHOST_STRING() {
        Lazy lazy = LOCALHOST_STRING$delegate;
        return (String)lazy.getValue();
    }

    @NotNull
    public final Inet4Address getWILDCARD() {
        Lazy lazy = WILDCARD$delegate;
        return (Inet4Address)lazy.getValue();
    }

    @NotNull
    public final String getWILDCARD_STRING() {
        Lazy lazy = WILDCARD_STRING$delegate;
        return (String)lazy.getValue();
    }

    public final int getLength() {
        return length;
    }

    public final boolean isFamily(@NotNull InetAddress address) {
        Intrinsics.checkNotNullParameter((Object)address, (String)"address");
        return address instanceof Inet4Address;
    }

    public final boolean isSiteLocal(@NotNull String ipAsString) {
        Intrinsics.checkNotNullParameter((Object)ipAsString, (String)"ipAsString");
        return this.isSiteLocal(this.toInt(ipAsString));
    }

    public final boolean isSiteLocal(int ipAsInt) {
        return this.isInRange(ipAsInt, private192, 16) || this.isInRange(ipAsInt, private172, 12) || this.isInRange(ipAsInt, private10, 8);
    }

    public final boolean isLoopback(@NotNull String ipAsString) {
        Intrinsics.checkNotNullParameter((Object)ipAsString, (String)"ipAsString");
        return this.isInRange(this.toInt(ipAsString), loopback127, 8);
    }

    public final boolean isLoopback(int ipAsInt) {
        return this.isInRange(ipAsInt, loopback127, 8);
    }

    public final boolean isValidCidr(@NotNull String ipAsString) {
        Intrinsics.checkNotNullParameter((Object)ipAsString, (String)"ipAsString");
        if (((CharSequence)ipAsString).length() == 0) {
            return false;
        }
        int slashIndex = StringsKt.indexOf$default((CharSequence)ipAsString, (char)'/', (int)0, (boolean)false, (int)6, null);
        if (slashIndex < 6) {
            return false;
        }
        String string = ipAsString.substring(0, slashIndex);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        String ipOnly = string;
        if (!this.isValid(ipOnly)) {
            return false;
        }
        try {
            String string2 = ipAsString.substring(slashIndex + 1);
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).substring(startIndex)");
            int cidr = Integer.parseInt(string2);
            boolean bl = 0 <= cidr ? cidr < 33 : false;
            if (bl) {
                return true;
            }
        }
        catch (Exception exception) {
            // empty catch block
        }
        return false;
    }

    public final boolean isValid(@NotNull String ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        return this.isValidIpV4Address$NetworkUtils(ip, 0, ip.length());
    }

    public final boolean isValidIpV4Address$NetworkUtils(@NotNull String ip, int from, int toExcluded) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        int len = toExcluded - from;
        if (!(7 <= len ? len < 16 : false)) {
            return false;
        }
        int from2 = from;
        int i = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)from2, (boolean)false, (int)4, null);
        if (i <= 0 || !this.isValidIpV4Word(ip, from2, i)) {
            return false;
        }
        from2 = i + 1;
        if ((i = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)from2, (boolean)false, (int)4, null)) <= 0 || !this.isValidIpV4Word(ip, from2, i)) {
            return false;
        }
        from2 = i + 1;
        if ((i = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)from2, (boolean)false, (int)4, null)) <= 0 || !this.isValidIpV4Word(ip, from2, i)) {
            return false;
        }
        return i > 0 && this.isValidIpV4Word(ip, i + 1, toExcluded);
    }

    /*
     * Enabled force condition propagation
     * Lifted jumps to return sites
     */
    private final boolean isValidIpV4Word(CharSequence word, int from, int toExclusive) {
        char c;
        int len = toExclusive - from;
        int c0 = 0;
        c0 = 32;
        char c1 = '\u0000';
        int c2 = 0;
        c2 = 32;
        if (len < 1) return false;
        if (len > 3) return false;
        char it = c = word.charAt(from);
        boolean bl = false;
        c0 = it;
        if (Intrinsics.compare((int)c, (int)48) < 0) {
            return false;
        }
        if (len == 3) {
            it = c = word.charAt(from + 1);
            boolean bl2 = false;
            c1 = it;
            if (Intrinsics.compare((int)c, (int)48) < 0) return false;
            it = c = word.charAt(from + 2);
            boolean bl3 = false;
            c2 = it;
            if (Intrinsics.compare((int)c, (int)48) < 0) return false;
            if (Intrinsics.compare((int)c0, (int)49) <= 0 && Intrinsics.compare((int)c1, (int)57) <= 0) {
                if (Intrinsics.compare((int)c2, (int)57) <= 0) return true;
            }
            if (c0 != 50) return false;
            if (Intrinsics.compare((int)c1, (int)53) > 0) return false;
            if (Intrinsics.compare((int)c2, (int)53) <= 0) return true;
            if (Intrinsics.compare((int)c1, (int)53) >= 0) return false;
            if (Intrinsics.compare((int)c2, (int)57) > 0) return false;
            return true;
        }
        if (Intrinsics.compare((int)c0, (int)57) > 0) return false;
        if (len == 1) return true;
        if (!this.isValidNumericChar$NetworkUtils(word.charAt(from + 1))) return false;
        return true;
    }

    public final boolean isValidNumericChar$NetworkUtils(char c) {
        return '0' <= c ? c < ':' : false;
    }

    public final boolean isValidIPv4MappedChar$NetworkUtils(char c) {
        return c == 'f' || c == 'F';
    }

    @Nullable
    public final byte[] toBytesOrNull(@NotNull String ip) {
        int it;
        int n;
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        if (!this.isValid(ip)) {
            return null;
        }
        int i = 0;
        byte[] byArray = new byte[4];
        int n2 = n = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)1, (boolean)false, (int)4, null);
        int n3 = 0;
        CharSequence charSequence = ip;
        IPv4 iPv4 = this;
        int n4 = 0;
        byte[] byArray2 = byArray;
        boolean bl = false;
        i = it;
        Unit unit = Unit.INSTANCE;
        byArray2[n4] = iPv4.ipv4WordToByte(charSequence, n3, n);
        it = n = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)(i + 2), (boolean)false, (int)4, null);
        n3 = i + 1;
        charSequence = ip;
        iPv4 = this;
        n4 = 1;
        byArray2 = byArray;
        boolean bl2 = false;
        i = it;
        unit = Unit.INSTANCE;
        byArray2[n4] = iPv4.ipv4WordToByte(charSequence, n3, n);
        it = n = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)(i + 2), (boolean)false, (int)4, null);
        n3 = i + 1;
        charSequence = ip;
        iPv4 = this;
        n4 = 2;
        byArray2 = byArray;
        boolean bl3 = false;
        i = it;
        unit = Unit.INSTANCE;
        byArray2[n4] = iPv4.ipv4WordToByte(charSequence, n3, n);
        byArray[3] = this.ipv4WordToByte(ip, i + 1, ip.length());
        return byArray;
    }

    @NotNull
    public final byte[] toBytes(@NotNull String ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        int i = 0;
        int index = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)1, (boolean)false, (int)4, null);
        byte a = this.ipv4WordToByte(ip, 0, index);
        i = index;
        index = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)(index + 2), (boolean)false, (int)4, null);
        byte b = this.ipv4WordToByte(ip, i + 1, index);
        i = index;
        index = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)(index + 2), (boolean)false, (int)4, null);
        byte c = this.ipv4WordToByte(ip, i + 1, index);
        i = index;
        byte[] byArray = new byte[]{a, b, c, this.ipv4WordToByte(ip, i + 1, ip.length())};
        return byArray;
    }

    @NotNull
    public final int[] toInts(@NotNull String ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        int i = 0;
        int index = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)1, (boolean)false, (int)4, null);
        int a = this.ipv4WordToInt(ip, 0, index);
        i = index;
        index = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)(index + 2), (boolean)false, (int)4, null);
        int b = this.ipv4WordToInt(ip, i + 1, index);
        i = index;
        index = StringsKt.indexOf$default((CharSequence)ip, (char)'.', (int)(index + 2), (boolean)false, (int)4, null);
        int c = this.ipv4WordToInt(ip, i + 1, index);
        i = index;
        int[] nArray = new int[]{a, b, c, this.ipv4WordToInt(ip, i + 1, ip.length())};
        return nArray;
    }

    private final int decimalDigit(CharSequence str, int pos) {
        return str.charAt(pos) - 48;
    }

    private final byte ipv4WordToByte(CharSequence ip, int from, int toExclusive) {
        return (byte)this.ipv4WordToInt(ip, from, toExclusive);
    }

    private final int ipv4WordToInt(CharSequence ip, int from, int toExclusive) {
        int newFrom = from;
        int ret = this.decimalDigit(ip, newFrom);
        if (++newFrom == toExclusive) {
            return ret;
        }
        ret = ret * 10 + this.decimalDigit(ip, newFrom);
        return ++newFrom == toExclusive ? ret : ret * 10 + this.decimalDigit(ip, newFrom);
    }

    /*
     * Exception decompiling
     */
    @Nullable
    public final byte[] findFreeSubnet24Cidr() {
        /*
         * This method has failed to decompile.  When submitting a bug report, please provide this stack trace, and (if you hold appropriate legal rights) the relevant class file.
         * 
         * org.benf.cfr.reader.util.ConfusedCFRException: Tried to end blocks [2[DOLOOP]], but top level block is 0[TRYBLOCK]
         *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.processEndingBlocks(Op04StructuredStatement.java:435)
         *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.buildNestedBlocks(Op04StructuredStatement.java:484)
         *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op03SimpleStatement.createInitialStructuredBlock(Op03SimpleStatement.java:736)
         *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysisInner(CodeAnalyser.java:850)
         *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysisOrWrapFail(CodeAnalyser.java:278)
         *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysis(CodeAnalyser.java:201)
         *     at org.benf.cfr.reader.entities.attributes.AttributeCode.analyse(AttributeCode.java:94)
         *     at org.benf.cfr.reader.entities.Method.analyse(Method.java:531)
         *     at org.benf.cfr.reader.entities.ClassFile.analyseMid(ClassFile.java:1055)
         *     at org.benf.cfr.reader.entities.ClassFile.analyseTop(ClassFile.java:942)
         *     at org.benf.cfr.reader.Driver.doJarVersionTypes(Driver.java:257)
         *     at org.benf.cfr.reader.Driver.doJar(Driver.java:139)
         *     at org.benf.cfr.reader.CfrDriverImpl.analyse(CfrDriverImpl.java:76)
         *     at org.benf.cfr.reader.Main.main(Main.java:54)
         */
        throw new IllegalStateException("Decompilation failed");
    }

    /*
     * WARNING - void declaration
     */
    public final boolean scanHosts(@NotNull String startingIp, int numberOfHosts) {
        void $this$toTypedArray$iv;
        Intrinsics.checkNotNullParameter((Object)startingIp, (String)"startingIp");
        Common.INSTANCE.getLogger$NetworkUtils().info("Scanning {} hosts, starting at IP {}.", (Object)numberOfHosts, (Object)startingIp);
        Object object = startingIp;
        Regex regex = SLASH_REGEX;
        int n = 0;
        object = regex.split((CharSequence)object, n);
        boolean $i$f$toTypedArray = false;
        void thisCollection$iv = $this$toTypedArray$iv;
        String[] stringArray = thisCollection$iv.toArray(new String[0]);
        Intrinsics.checkNotNull((Object)stringArray, (String)"null cannot be cast to non-null type kotlin.Array<T of kotlin.collections.ArraysKt__ArraysJVMKt.toTypedArray>");
        String[] split = stringArray;
        byte a = Byte.parseByte(split[0]);
        byte b = Byte.parseByte(split[1]);
        byte c = Byte.parseByte(split[2]);
        byte d = Byte.parseByte(split[3]);
        byte[] byArray = new byte[]{a, b, c, d};
        byte[] ip = byArray;
        int counter = numberOfHosts;
        while (counter >= 0) {
            --counter;
            byte by = ip[3];
            ip[3] = (byte)(by + 1);
            if (ip[3] > 255) {
                ip[3] = 1;
                by = ip[2];
                ip[2] = (byte)(by + 1);
            }
            if (ip[2] > 255) {
                ip[2] = 0;
                by = ip[1];
                ip[1] = (byte)(by + 1);
            }
            if (ip[1] > 255) {
                Common.INSTANCE.getLogger$NetworkUtils().error("Exhausted all ip searches. FATAL ERROR.");
                return false;
            }
            try {
                InetAddress address = InetAddress.getByAddress(ip);
                boolean reachable = address.isReachable(100);
                if (!reachable) continue;
                Common.INSTANCE.getLogger$NetworkUtils().error("IP address {} is already reachable on the network. Unable to continue.", (Object)address.getHostAddress());
                return false;
            }
            catch (IOException e) {
                Common.INSTANCE.getLogger$NetworkUtils().error("Error pinging the IP address", (Throwable)e);
                return false;
            }
        }
        return true;
    }

    @NotNull
    public final String getCidrAsNetmask(int cidr) {
        String string;
        switch (cidr) {
            case 32: {
                string = "255.255.255.255";
                break;
            }
            case 31: {
                string = "255.255.255.254";
                break;
            }
            case 30: {
                string = "255.255.255.252";
                break;
            }
            case 29: {
                string = "255.255.255.248";
                break;
            }
            case 28: {
                string = "255.255.255.240";
                break;
            }
            case 27: {
                string = "255.255.255.224";
                break;
            }
            case 26: {
                string = "255.255.255.192";
                break;
            }
            case 25: {
                string = "255.255.255.128";
                break;
            }
            case 24: {
                string = "255.255.255.0";
                break;
            }
            case 23: {
                string = "255.255.254.0";
                break;
            }
            case 22: {
                string = "255.255.252.0";
                break;
            }
            case 21: {
                string = "255.255.248.0";
                break;
            }
            case 20: {
                string = "255.255.240.0";
                break;
            }
            case 19: {
                string = "255.255.224.0";
                break;
            }
            case 18: {
                string = "255.255.192.0";
                break;
            }
            case 17: {
                string = "255.255.128.0";
                break;
            }
            case 16: {
                string = "255.255.0.0";
                break;
            }
            case 15: {
                string = "255.254.0.0";
                break;
            }
            case 14: {
                string = "255.252.0.0";
                break;
            }
            case 13: {
                string = "255.248.0.0";
                break;
            }
            case 12: {
                string = "255.240.0.0";
                break;
            }
            case 11: {
                string = "255.224.0.0";
                break;
            }
            case 10: {
                string = "255.192.0.0";
                break;
            }
            case 9: {
                string = "255.128.0.0";
                break;
            }
            case 8: {
                string = "255.0.0.0";
                break;
            }
            case 7: {
                string = "254.0.0.0";
                break;
            }
            case 6: {
                string = "252.0.0.0";
                break;
            }
            case 5: {
                string = "248.0.0.0";
                break;
            }
            case 4: {
                string = "240.0.0.0";
                break;
            }
            case 3: {
                string = "224.0.0.0";
                break;
            }
            case 2: {
                string = "192.0.0.0";
                break;
            }
            case 1: {
                string = "128.0.0.0";
                break;
            }
            default: {
                string = "0.0.0.0";
            }
        }
        return string;
    }

    public final int cidrPrefixToSubnetMask(int cidrPrefix) {
        return (int)(-1L << 32 - cidrPrefix & 0xFFFFFFFFFFFFFFFFL);
    }

    public final int cidrPrefixFromSubnetMask(@NotNull String mask) {
        int n;
        Intrinsics.checkNotNullParameter((Object)mask, (String)"mask");
        switch (mask) {
            case "255.255.255.255": {
                n = 32;
                break;
            }
            case "255.255.255.254": {
                n = 31;
                break;
            }
            case "255.255.255.252": {
                n = 30;
                break;
            }
            case "255.255.255.248": {
                n = 29;
                break;
            }
            case "255.255.255.240": {
                n = 28;
                break;
            }
            case "255.255.255.224": {
                n = 27;
                break;
            }
            case "255.255.255.192": {
                n = 26;
                break;
            }
            case "255.255.255.128": {
                n = 25;
                break;
            }
            case "255.255.255.0": {
                n = 24;
                break;
            }
            case "255.255.254.0": {
                n = 23;
                break;
            }
            case "255.255.252.0": {
                n = 22;
                break;
            }
            case "255.255.248.0": {
                n = 21;
                break;
            }
            case "255.255.240.0": {
                n = 20;
                break;
            }
            case "255.255.224.0": {
                n = 19;
                break;
            }
            case "255.255.192.0": {
                n = 18;
                break;
            }
            case "255.255.128.0": {
                n = 17;
                break;
            }
            case "255.255.0.0": {
                n = 16;
                break;
            }
            case "255.254.0.0": {
                n = 15;
                break;
            }
            case "255.252.0.0": {
                n = 14;
                break;
            }
            case "255.248.0.0": {
                n = 13;
                break;
            }
            case "255.240.0.0": {
                n = 12;
                break;
            }
            case "255.224.0.0": {
                n = 11;
                break;
            }
            case "255.192.0.0": {
                n = 10;
                break;
            }
            case "255.128.0.0": {
                n = 9;
                break;
            }
            case "255.0.0.0": {
                n = 8;
                break;
            }
            case "254.0.0.0": {
                n = 7;
                break;
            }
            case "252.0.0.0": {
                n = 6;
                break;
            }
            case "248.0.0.0": {
                n = 5;
                break;
            }
            case "240.0.0.0": {
                n = 4;
                break;
            }
            case "224.0.0.0": {
                n = 3;
                break;
            }
            case "192.0.0.0": {
                n = 2;
                break;
            }
            case "128.0.0.0": {
                n = 1;
                break;
            }
            default: {
                n = 0;
            }
        }
        return n;
    }

    @NotNull
    public final List<String> range2Cidr(@NotNull String startIp, @NotNull String endIp) {
        byte maxsize;
        Intrinsics.checkNotNullParameter((Object)startIp, (String)"startIp");
        Intrinsics.checkNotNullParameter((Object)endIp, (String)"endIp");
        long end = this.toInt(endIp);
        List pairs = new ArrayList();
        for (long start = (long)this.toInt(startIp); end >= start; start += (long)Math.pow(2.0, (double)32 - (double)maxsize)) {
            long mask;
            long maskedBase;
            maxsize = 32;
            while (maxsize > 0 && (maskedBase = start & (mask = (long)CIDR2MASK[maxsize - 1])) == start) {
                byte by = maxsize;
                maxsize = (byte)(by + -1);
            }
            double x = Math.log((double)(end - start) + 1.0) / Math.log(2.0);
            byte maxDiff = (byte)((double)32 - Math.floor(x));
            if (maxsize < maxDiff) {
                maxsize = maxDiff;
            }
            String ip = this.toString(start);
            pairs.add(ip + '/' + maxsize);
        }
        return pairs;
    }

    public final boolean isInRange(@NotNull String address, @NotNull String networkAddress, int networkPrefix) {
        Intrinsics.checkNotNullParameter((Object)address, (String)"address");
        Intrinsics.checkNotNullParameter((Object)networkAddress, (String)"networkAddress");
        return this.isInRange(this.toInt(address), this.toInt(networkAddress), networkPrefix);
    }

    public final boolean isInRange(int address, int networkAddress, int networkPrefix) {
        if (networkPrefix == 0) {
            return true;
        }
        int netmask = ~((1 << 32 - networkPrefix) - 1);
        int network = UInt.constructor-impl((int)(networkAddress & netmask));
        int broadcast = UInt.constructor-impl((int)(network | UInt.constructor-impl((int)(~netmask))));
        int n = UInt.constructor-impl((int)address);
        return 0 <= UnsignedKt.uintCompare((int)n, (int)network) ? UnsignedKt.uintCompare((int)n, (int)broadcast) <= 0 : false;
    }

    public final int toInt(@NotNull byte[] ipBytes) {
        Intrinsics.checkNotNullParameter((Object)ipBytes, (String)"ipBytes");
        return ipBytes[0] << 24 | ipBytes[1] << 16 | ipBytes[2] << 8 | ipBytes[3];
    }

    public final int toInt(@NotNull String ipAsString) {
        Intrinsics.checkNotNullParameter((Object)ipAsString, (String)"ipAsString");
        return this.isValid(ipAsString) ? this.toIntUnsafe(ipAsString) : 0;
    }

    public final int toIntUnsafe(@NotNull String ipAsString) {
        Intrinsics.checkNotNullParameter((Object)ipAsString, (String)"ipAsString");
        byte[] bytes = this.toBytes(ipAsString);
        int address = 0;
        for (byte element : bytes) {
            address <<= 8;
            address |= element & 0xFF;
        }
        return address;
    }

    @NotNull
    public final String toString(int ipAddress) {
        StringBuilder buf = new StringBuilder(15);
        this.toString(ipAddress, buf);
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    public final void toString(int ipAddress, @NotNull StringBuilder buf) {
        Intrinsics.checkNotNullParameter((Object)buf, (String)"buf");
        buf.append(ipAddress >> 24 & 0xFF);
        buf.append('.');
        buf.append(ipAddress >> 16 & 0xFF);
        buf.append('.');
        buf.append(ipAddress >> 8 & 0xFF);
        buf.append('.');
        buf.append(ipAddress & 0xFF);
    }

    @NotNull
    public final String toString(@NotNull byte[] ipBytes) {
        Intrinsics.checkNotNullParameter((Object)ipBytes, (String)"ipBytes");
        StringBuilder buf = new StringBuilder(15);
        this.toString(ipBytes, buf);
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    public final void toString(@NotNull byte[] ipBytes, @NotNull StringBuilder buf) {
        Intrinsics.checkNotNullParameter((Object)ipBytes, (String)"ipBytes");
        Intrinsics.checkNotNullParameter((Object)buf, (String)"buf");
        buf.append(ipBytes[0] & 0xFF);
        buf.append('.');
        buf.append(ipBytes[1] & 0xFF);
        buf.append('.');
        buf.append(ipBytes[2] & 0xFF);
        buf.append('.');
        buf.append(ipBytes[3] & 0xFF);
    }

    @NotNull
    public final String toString(@NotNull int[] ipInts) {
        Intrinsics.checkNotNullParameter((Object)ipInts, (String)"ipInts");
        StringBuilder buf = new StringBuilder(15);
        this.toString(ipInts, buf);
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    public final void toString(@NotNull int[] ipInts, @NotNull StringBuilder buf) {
        Intrinsics.checkNotNullParameter((Object)ipInts, (String)"ipInts");
        Intrinsics.checkNotNullParameter((Object)buf, (String)"buf");
        buf.append(ipInts[0]);
        buf.append('.');
        buf.append(ipInts[1]);
        buf.append('.');
        buf.append(ipInts[2]);
        buf.append('.');
        buf.append(ipInts[3]);
    }

    @NotNull
    public final String toString(@NotNull Inet4Address ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        String string = ip.getHostAddress();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"ip.hostAddress");
        return string;
    }

    public final void writeString(int ipAddress, @NotNull Writer writer) throws Exception {
        Intrinsics.checkNotNullParameter((Object)writer, (String)"writer");
        writer.write(String.valueOf(ipAddress >> 24 & 0xFF));
        writer.write(46);
        writer.write(String.valueOf(ipAddress >> 16 & 0xFF));
        writer.write(46);
        writer.write(String.valueOf(ipAddress >> 8 & 0xFF));
        writer.write(46);
        writer.write(String.valueOf(ipAddress & 0xFF));
    }

    @NotNull
    public final String toString(long ipAddress) {
        StringBuilder ipString = new StringBuilder(15);
        ipString.append(ipAddress >> 24 & 0xFFL);
        ipString.append('.');
        ipString.append(ipAddress >> 16 & 0xFFL);
        ipString.append('.');
        ipString.append(ipAddress >> 8 & 0xFFL);
        ipString.append('.');
        ipString.append(ipAddress & 0xFFL);
        String string = ipString.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"ipString.toString()");
        return string;
    }

    @NotNull
    public final byte[] toBytes(int bytes) {
        byte[] byArray = new byte[]{(byte)(bytes >> 24 & 0xFF), (byte)(bytes >> 16 & 0xFF), (byte)(bytes >> 8 & 0xFF), (byte)(bytes & 0xFF)};
        return byArray;
    }

    @NotNull
    public final Inet4Address toAddressUnsafe(@NotNull String ip) throws UnknownHostException {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        byte[] asBytes = this.toBytes(ip);
        InetAddress inetAddress = Inet4Address.getByAddress(null, asBytes);
        Intrinsics.checkNotNull((Object)inetAddress, (String)"null cannot be cast to non-null type java.net.Inet4Address");
        return (Inet4Address)inetAddress;
    }

    @Nullable
    public final Inet4Address toAddress(@NotNull String ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        if (this.isValid(ip)) {
            return this.toAddressUnsafe(ip);
        }
        return null;
    }

    @Nullable
    public final InetAddress truncate(@NotNull Inet4Address address, int maskLength) {
        InetAddress inetAddress;
        Intrinsics.checkNotNullParameter((Object)address, (String)"address");
        int maxMaskLength = IPv6.INSTANCE.getLength() * 8;
        if (!(maskLength >= 0 && maskLength <= maxMaskLength)) {
            boolean $i$a$-require-IPv4$truncate$22 = false;
            String $i$a$-require-IPv4$truncate$22 = "invalid mask length";
            throw new IllegalArgumentException($i$a$-require-IPv4$truncate$22.toString());
        }
        if (maskLength == maxMaskLength) {
            return address;
        }
        byte[] bytes = address.getAddress();
        int n = bytes.length;
        for (int i = maskLength / 8 + 1; i < n; ++i) {
            bytes[i] = 0;
        }
        int maskBits = maskLength % 8;
        int bitmask = 0;
        for (int i = 0; i < maskBits; ++i) {
            bitmask |= 1 << 7 - i;
        }
        bytes[maskLength / 8] = (byte)(bytes[maskLength / 8] & bitmask);
        try {
            inetAddress = InetAddress.getByAddress(bytes);
        }
        catch (UnknownHostException e) {
            throw new IllegalArgumentException("invalid address");
        }
        return inetAddress;
    }

    static {
        int[] nArray = new int[]{0, Integer.MIN_VALUE, -1073741824, -536870912, -268435456, -134217728, -67108864, -33554432, -16777216, -8388608, -4194304, -2097152, -1048576, -524288, -262144, -131072, -65536, Short.MIN_VALUE, -16384, -8192, -4096, -2048, -1024, -512, -256, -128, -64, -32, -16, -8, -4, -2, -1};
        CIDR2MASK = nArray;
    }
}

