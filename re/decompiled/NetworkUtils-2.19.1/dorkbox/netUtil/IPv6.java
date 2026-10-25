/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil;

import dorkbox.netUtil.Common;
import dorkbox.netUtil.IPv4;
import dorkbox.netUtil.IPv6;
import java.math.BigInteger;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000t\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\b\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0010\u000b\n\u0002\b\n\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\r\n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\f\n\u0002\b\u0007\n\u0002\u0010\u0005\n\u0002\b\u0006\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0015\n\u0002\b\n\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010)\u001a\u00020\u00182\u0006\u0010*\u001a\u00020\u0004J\u001c\u0010+\u001a\u0004\u0018\u00010,2\u0006\u0010-\u001a\u00020.2\b\b\u0002\u0010/\u001a\u00020!H\u0002J \u00100\u001a\u00020!2\u0006\u00101\u001a\u00020\u00042\u0006\u00102\u001a\u00020\u00042\u0006\u00103\u001a\u00020\u0004H\u0002J\u000e\u00104\u001a\u00020!2\u0006\u00105\u001a\u000206J\u000e\u00107\u001a\u00020!2\u0006\u00108\u001a\u00020\u0013J\u000e\u00109\u001a\u00020!2\u0006\u0010-\u001a\u00020\u0013J\u0010\u0010:\u001a\u00020!2\u0006\u0010;\u001a\u00020<H\u0002J(\u0010=\u001a\u00020!2\u0006\u0010>\u001a\u00020,2\u0006\u0010?\u001a\u00020\u00042\u0006\u0010@\u001a\u00020\u00042\u0006\u0010A\u001a\u00020\u0004H\u0002J \u0010B\u001a\u00020!2\u0006\u0010C\u001a\u00020D2\u0006\u0010E\u001a\u00020D2\u0006\u0010F\u001a\u00020!H\u0002J \u0010G\u001a\u00020!2\u0006\u0010>\u001a\u00020,2\u0006\u0010H\u001a\u00020\u00042\u0006\u0010%\u001a\u00020\u0004H\u0002J\u0010\u0010I\u001a\u0004\u0018\u00010\r2\u0006\u0010-\u001a\u00020\u0013J\u001a\u0010I\u001a\u0004\u0018\u00010\r2\u0006\u0010-\u001a\u00020\u00132\b\b\u0002\u0010/\u001a\u00020!J,\u0010J\u001a\u00020K2\u0006\u0010>\u001a\u00020,2\u0006\u0010L\u001a\u00020\u00042\u0006\u0010/\u001a\u00020!2\n\u0010M\u001a\u00060Nj\u0002`OH\u0002J,\u0010J\u001a\u00020K2\u0006\u0010P\u001a\u00020Q2\u0006\u0010L\u001a\u00020\u00042\u0006\u0010/\u001a\u00020!2\n\u0010M\u001a\u00060Nj\u0002`OH\u0002J\u000e\u0010R\u001a\u00020,2\u0006\u0010S\u001a\u00020\u0013J\u0010\u0010T\u001a\u0004\u0018\u00010,2\u0006\u0010S\u001a\u00020\u0013J\u000e\u0010U\u001a\u00020\u00182\u0006\u0010V\u001a\u00020,J\u000e\u0010U\u001a\u00020\u00182\u0006\u00108\u001a\u00020\u0013J\u000e\u0010W\u001a\u00020\u00182\u0006\u00108\u001a\u00020\u0013J\u0018\u0010X\u001a\u00020\u00132\u0006\u0010-\u001a\u00020\r2\b\b\u0002\u0010/\u001a\u00020!J$\u0010X\u001a\u00020K2\u0006\u0010-\u001a\u00020\r2\b\b\u0002\u0010/\u001a\u00020!2\n\u0010M\u001a\u00060Nj\u0002`OJ\u000e\u0010X\u001a\u00020\u00132\u0006\u0010>\u001a\u00020,J\u0016\u0010X\u001a\u00020\u00132\u0006\u0010>\u001a\u00020,2\u0006\u0010L\u001a\u00020\u0004J\"\u0010X\u001a\u00020K2\u0006\u0010>\u001a\u00020,2\u0006\u0010L\u001a\u00020\u00042\n\u0010M\u001a\u00060Nj\u0002`OJ\u001a\u0010X\u001a\u00020K2\u0006\u0010>\u001a\u00020,2\n\u0010M\u001a\u00060Nj\u0002`OJ\u000e\u0010X\u001a\u00020\u00132\u0006\u0010P\u001a\u00020QJ\u0016\u0010X\u001a\u00020\u00132\u0006\u0010P\u001a\u00020Q2\u0006\u0010L\u001a\u00020\u0004J\"\u0010X\u001a\u00020K2\u0006\u0010P\u001a\u00020Q2\u0006\u0010L\u001a\u00020\u00042\n\u0010M\u001a\u00060Nj\u0002`OJ\u001a\u0010X\u001a\u00020K2\u0006\u0010P\u001a\u00020Q2\n\u0010M\u001a\u00060Nj\u0002`OJ\u0018\u0010Y\u001a\u0004\u0018\u0001062\u0006\u00105\u001a\u00020\r2\u0006\u0010Z\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u001b\u0010\f\u001a\u00020\r8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0010\u0010\u0011\u001a\u0004\b\u000e\u0010\u000fR\u001b\u0010\u0012\u001a\u00020\u00138FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0016\u0010\u0011\u001a\u0004\b\u0014\u0010\u0015R\u0016\u0010\u0017\u001a\n \u0019*\u0004\u0018\u00010\u00180\u0018X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001b\u0010\u001a\u001a\u00020\r8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001c\u0010\u0011\u001a\u0004\b\u001b\u0010\u000fR\u001b\u0010\u001d\u001a\u00020\u00138FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001f\u0010\u0011\u001a\u0004\b\u001e\u0010\u0015R\u001b\u0010 \u001a\u00020!8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b#\u0010\u0011\u001a\u0004\b \u0010\"R\u0011\u0010$\u001a\u00020!\u00a2\u0006\b\n\u0000\u001a\u0004\b$\u0010\"R\u0014\u0010%\u001a\u00020\u0004X\u0086D\u00a2\u0006\b\n\u0000\u001a\u0004\b&\u0010'R\u000e\u0010(\u001a\u00020\u0013X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006["}, d2={"Ldorkbox/netUtil/IPv6;", "", "()V", "IPV4_MAX_CHAR_BETWEEN_SEPARATOR", "", "IPV4_SEPARATORS", "IPV6_BYTE_COUNT", "IPV6_MAX_CHAR_BETWEEN_SEPARATOR", "IPV6_MAX_CHAR_COUNT", "IPV6_MAX_SEPARATORS", "IPV6_MIN_SEPARATORS", "IPV6_WORD_COUNT", "LOCALHOST", "Ljava/net/Inet6Address;", "getLOCALHOST", "()Ljava/net/Inet6Address;", "LOCALHOST$delegate", "Lkotlin/Lazy;", "LOCALHOST_STRING", "", "getLOCALHOST_STRING", "()Ljava/lang/String;", "LOCALHOST_STRING$delegate", "MINUS_ONE", "Ljava/math/BigInteger;", "kotlin.jvm.PlatformType", "WILDCARD", "getWILDCARD", "WILDCARD$delegate", "WILDCARD_STRING", "getWILDCARD_STRING", "WILDCARD_STRING$delegate", "isAvailable", "", "()Z", "isAvailable$delegate", "isPreferred", "length", "getLength", "()I", "version", "cidrPrefixToSubnetMask", "cidrPrefix", "getIPv6ByName", "", "ip", "", "ipv4Mapped", "inRangeEndExclusive", "value", "start", "end", "isFamily", "address", "Ljava/net/InetAddress;", "isLoopback", "ipAsString", "isValid", "isValidHexChar", "c", "", "isValidIPv4Mapped", "bytes", "currentIndex", "compressBegin", "compressLength", "isValidIPv4MappedSeparators", "b0", "", "b1", "mustBeZero", "isZero", "startPos", "toAddress", "toAddressString", "", "offset", "buf", "Ljava/lang/StringBuilder;", "Lkotlin/text/StringBuilder;", "ints", "", "toBytes", "ipAddress", "toBytesOrNull", "toInt", "ipBytes", "toIntUnsafe", "toString", "truncate", "maskLength", "NetworkUtils"})
public final class IPv6 {
    @NotNull
    public static final IPv6 INSTANCE = new IPv6();
    @NotNull
    public static final String version = "2.19.1";
    private static final BigInteger MINUS_ONE = BigInteger.valueOf(-1L);
    private static final int IPV6_MAX_CHAR_BETWEEN_SEPARATOR = 4;
    private static final int IPV6_MIN_SEPARATORS = 2;
    private static final int IPV6_MAX_SEPARATORS = 8;
    private static final int IPV4_MAX_CHAR_BETWEEN_SEPARATOR = 3;
    private static final int IPV4_SEPARATORS = 3;
    private static final int IPV6_BYTE_COUNT = 16;
    private static final int IPV6_WORD_COUNT = 8;
    private static final int IPV6_MAX_CHAR_COUNT = 39;
    private static final boolean isPreferred = Common.INSTANCE.getBoolean("java.net.preferIPv6Addresses", false);
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
    private static final int length = 16;

    private IPv6() {
    }

    public final boolean isPreferred() {
        return isPreferred;
    }

    public final boolean isAvailable() {
        Lazy lazy = isAvailable$delegate;
        return (Boolean)lazy.getValue();
    }

    @NotNull
    public final Inet6Address getLOCALHOST() {
        Lazy lazy = LOCALHOST$delegate;
        return (Inet6Address)lazy.getValue();
    }

    @NotNull
    public final String getLOCALHOST_STRING() {
        Lazy lazy = LOCALHOST_STRING$delegate;
        return (String)lazy.getValue();
    }

    @NotNull
    public final Inet6Address getWILDCARD() {
        Lazy lazy = WILDCARD$delegate;
        return (Inet6Address)lazy.getValue();
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
        return address instanceof Inet6Address;
    }

    public final boolean isValid(@NotNull String ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        int end = ip.length();
        if (end < 2) {
            return false;
        }
        int start = 0;
        char c = ip.charAt(0);
        if (c == '[') {
            if (ip.charAt(--end) != ']') {
                return false;
            }
            start = 1;
            c = ip.charAt(1);
        } else {
            start = 0;
        }
        int colons = 0;
        int compressBegin = 0;
        if (c == ':') {
            if (ip.charAt(start + 1) != ':') {
                return false;
            }
            colons = 2;
            compressBegin = start;
            start += 2;
        } else {
            colons = 0;
            compressBegin = -1;
        }
        int wordLen = 0;
        int n = end;
        for (int i = start; i < n; ++i) {
            c = ip.charAt(i);
            if (this.isValidHexChar(c)) {
                if (wordLen < 4) {
                    ++wordLen;
                    continue;
                }
                return false;
            }
            char c2 = c;
            if (c2 == ':') {
                if (colons > 7) {
                    return false;
                }
                if (ip.charAt(i - 1) == ':') {
                    if (compressBegin >= 0) {
                        return false;
                    }
                    compressBegin = i - 1;
                } else {
                    wordLen = 0;
                }
                ++colons;
                continue;
            }
            if (c2 == '.') {
                if (compressBegin < 0 && colons != 6 || colons == 7 && compressBegin >= start || colons > 7) {
                    return false;
                }
                int ipv4Start = i - wordLen;
                int j = ipv4Start - 2;
                if (IPv4.INSTANCE.isValidIPv4MappedChar$NetworkUtils(ip.charAt(j))) {
                    if (!(IPv4.INSTANCE.isValidIPv4MappedChar$NetworkUtils(ip.charAt(j - 1)) && IPv4.INSTANCE.isValidIPv4MappedChar$NetworkUtils(ip.charAt(j - 2)) && IPv4.INSTANCE.isValidIPv4MappedChar$NetworkUtils(ip.charAt(j - 3)))) {
                        return false;
                    }
                    j -= 5;
                }
                while (j >= start) {
                    char tmpChar = ip.charAt(j);
                    if (tmpChar != '0' && tmpChar != ':') {
                        return false;
                    }
                    --j;
                }
                int ipv4End = StringsKt.indexOf$default((CharSequence)ip, (char)'%', (int)(ipv4Start + 7), (boolean)false, (int)4, null);
                if (ipv4End < 0) {
                    ipv4End = end;
                }
                return IPv4.INSTANCE.isValidIpV4Address$NetworkUtils(ip, ipv4Start, ipv4End);
            }
            if (c2 == '%') {
                end = i;
                break;
            }
            return false;
        }
        return compressBegin < 0 ? colons == 7 && wordLen > 0 : compressBegin + 2 == end || wordLen > 0 && (colons < 8 || compressBegin <= start);
    }

    /*
     * Enabled force condition propagation
     * Lifted jumps to return sites
     */
    private final boolean isValidHexChar(char c) {
        boolean bl;
        boolean bl2;
        if ('0' <= c) {
            if (c < ':') {
                return true;
            }
            bl2 = false;
        } else {
            bl2 = false;
        }
        if (bl2) return true;
        if ('A' <= c) {
            if (c < 'G') {
                return true;
            }
            bl = false;
        } else {
            bl = false;
        }
        if (bl) return true;
        if ('a' > c) return false;
        if (c >= 'g') return false;
        return true;
    }

    @Nullable
    public final Inet6Address toAddress(@NotNull String ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        return this.toAddress(ip, true);
    }

    @Nullable
    public final Inet6Address toAddress(@NotNull String ip, boolean ipv4Mapped) {
        Inet6Address inet6Address;
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        byte[] byArray = this.getIPv6ByName(ip, ipv4Mapped);
        if (byArray == null) {
            return null;
        }
        byte[] bytes = byArray;
        try {
            inet6Address = Inet6Address.getByAddress(null, bytes, -1);
        }
        catch (UnknownHostException e) {
            throw new RuntimeException(e);
        }
        return inet6Address;
    }

    public static /* synthetic */ Inet6Address toAddress$default(IPv6 iPv6, String string, boolean bl, int n, Object object) {
        if ((n & 2) != 0) {
            bl = true;
        }
        return iPv6.toAddress(string, bl);
    }

    private final byte[] getIPv6ByName(CharSequence ip, boolean ipv4Mapped) {
        boolean isCompressed;
        int i;
        byte[] bytes = new byte[16];
        int ipLength = ip.length();
        int compressBegin = 0;
        int compressLength = 0;
        int currentIndex = 0;
        int value = 0;
        int begin = -1;
        int ipv6Separators = 0;
        int ipv4Separators = 0;
        int tmp = 0;
        boolean needsShift = false;
        for (i = 0; i < ipLength; ++i) {
            char c = ip.charAt(i);
            char c2 = c;
            if (c2 == ':') {
                if (i - begin > 4 || ipv4Separators > 0 || ++ipv6Separators > 8 || currentIndex + 1 >= bytes.length) {
                    return null;
                }
                value <<= 4 - (i - begin) << 2;
                if (compressLength > 0) {
                    compressLength -= 2;
                }
                bytes[currentIndex++] = (byte)((value & 0xF) << 4 | value >> 4 & 0xF);
                bytes[currentIndex++] = (byte)((value >> 8 & 0xF) << 4 | value >> 12 & 0xF);
                tmp = i + 1;
                if (tmp < ipLength && ip.charAt(tmp) == ':') {
                    if (compressBegin != 0 || ++tmp < ipLength && ip.charAt(tmp) == ':') {
                        return null;
                    }
                    needsShift = ++ipv6Separators == 2 && value == 0;
                    compressBegin = currentIndex;
                    compressLength = bytes.length - compressBegin - 2;
                    ++i;
                }
                value = 0;
                begin = -1;
                continue;
            }
            if (c2 == '.') {
                tmp = i - begin;
                if (tmp > 3 || begin < 0 || ++ipv4Separators > 3 || ipv6Separators > 0 && currentIndex + compressLength < 12 || i + 1 >= ipLength || currentIndex >= bytes.length || ipv4Separators == 1 && (!ipv4Mapped || currentIndex != 0 && !this.isValidIPv4Mapped(bytes, currentIndex, compressBegin, compressLength) || tmp == 3 && (!IPv4.INSTANCE.isValidNumericChar$NetworkUtils(ip.charAt(i - 1)) || !IPv4.INSTANCE.isValidNumericChar$NetworkUtils(ip.charAt(i - 2)) || !IPv4.INSTANCE.isValidNumericChar$NetworkUtils(ip.charAt(i - 3))) || tmp == 2 && (!IPv4.INSTANCE.isValidNumericChar$NetworkUtils(ip.charAt(i - 1)) || !IPv4.INSTANCE.isValidNumericChar$NetworkUtils(ip.charAt(i - 2))) || tmp == 1 && !IPv4.INSTANCE.isValidNumericChar$NetworkUtils(ip.charAt(i - 1)))) {
                    return null;
                }
                if ((begin = ((value <<= 3 - tmp << 2) & 0xF) * 100 + (value >> 4 & 0xF) * 10 + (value >> 8 & 0xF)) < 0 || begin > 255) {
                    return null;
                }
                bytes[currentIndex++] = (byte)begin;
                value = 0;
                begin = -1;
                continue;
            }
            if (!this.isValidHexChar(c) || ipv4Separators > 0 && !IPv4.INSTANCE.isValidNumericChar$NetworkUtils(c)) {
                return null;
            }
            if (begin < 0) {
                begin = i;
            } else if (i - begin > 4) {
                return null;
            }
            value += Common.INSTANCE.decodeHexNibble(c) << (i - begin << 2);
        }
        boolean bl = isCompressed = compressBegin > 0;
        if (ipv4Separators > 0) {
            if (begin > 0 && i - begin > 3 || ipv4Separators != 3 || currentIndex >= bytes.length) {
                return null;
            }
            if (ipv6Separators == 0) {
                compressLength = 12;
            } else if (ipv6Separators >= 2 && (!isCompressed && ipv6Separators == 6 && ip.charAt(0) != ':' || isCompressed && ipv6Separators < 8 && (ip.charAt(0) != ':' || compressBegin <= 2))) {
                compressLength -= 2;
            } else {
                return null;
            }
            value <<= 3 - (i - begin) << 2;
            begin = (value & 0xF) * 100 + (value >> 4 & 0xF) * 10 + (value >> 8 & 0xF);
            if (begin < 0 || begin > 255) {
                return null;
            }
            bytes[currentIndex++] = (byte)begin;
        } else {
            tmp = ipLength - 1;
            if (begin > 0 && i - begin > 4 || ipv6Separators < 2 || !isCompressed && (ipv6Separators + 1 != 8 || ip.charAt(0) == ':' || ip.charAt(tmp) == ':') || isCompressed && (ipv6Separators > 8 || ipv6Separators == 8 && (compressBegin <= 2 && ip.charAt(0) != ':' || compressBegin >= 14 && ip.charAt(tmp) != ':')) || currentIndex + 1 >= bytes.length || begin < 0 && ip.charAt(tmp - 1) != ':' || compressBegin > 2 && ip.charAt(0) == ':') {
                return null;
            }
            if (begin >= 0 && i - begin <= 4) {
                value <<= 4 - (i - begin) << 2;
            }
            bytes[currentIndex++] = (byte)((value & 0xF) << 4 | value >> 4 & 0xF);
            bytes[currentIndex++] = (byte)((value >> 8 & 0xF) << 4 | value >> 12 & 0xF);
        }
        i = currentIndex + compressLength;
        if (needsShift || i >= bytes.length) {
            if (i >= bytes.length) {
                ++compressBegin;
            }
            for (i = currentIndex; i < bytes.length; ++i) {
                for (begin = bytes.length - 1; begin >= compressBegin; --begin) {
                    bytes[begin] = bytes[begin - 1];
                }
                bytes[begin] = 0;
                ++compressBegin;
            }
        } else {
            for (i = 0; i < compressLength && (currentIndex = (begin = i + compressBegin) + compressLength) < bytes.length; ++i) {
                bytes[currentIndex] = bytes[begin];
                bytes[begin] = 0;
            }
        }
        if (ipv4Separators > 0) {
            bytes[11] = -1;
            bytes[10] = bytes[11];
        }
        return bytes;
    }

    static /* synthetic */ byte[] getIPv6ByName$default(IPv6 iPv6, CharSequence charSequence, boolean bl, int n, Object object) {
        if ((n & 2) != 0) {
            bl = true;
        }
        return iPv6.getIPv6ByName(charSequence, bl);
    }

    private final boolean isValidIPv4Mapped(byte[] bytes, int currentIndex, int compressBegin, int compressLength) {
        boolean mustBeZero = compressBegin + compressLength >= 14;
        return currentIndex <= 12 && currentIndex >= 2 && (!mustBeZero || compressBegin < 12) && this.isValidIPv4MappedSeparators(bytes[currentIndex - 1], bytes[currentIndex - 2], mustBeZero) && this.isZero(bytes, 0, currentIndex - 3);
    }

    private final boolean isZero(byte[] bytes, int startPos, int length) {
        int start = startPos;
        int end = start + length;
        boolean zeroByteByte = false;
        while (start < end) {
            if (bytes[start++] == 0) continue;
            return false;
        }
        return true;
    }

    private final boolean isValidIPv4MappedSeparators(byte b0, byte b1, boolean mustBeZero) {
        return b0 == b1 && (b0 == 0 || !mustBeZero && b1 == -1);
    }

    @Nullable
    public final byte[] toBytesOrNull(@NotNull String ipAddress) {
        Intrinsics.checkNotNullParameter((Object)ipAddress, (String)"ipAddress");
        if (this.isValid(ipAddress)) {
            Inet6Address inet6Address = this.toAddress(ipAddress);
            return (byte[])(inet6Address != null ? inet6Address.getAddress() : null);
        }
        return null;
    }

    @NotNull
    public final byte[] toBytes(@NotNull String ipAddress) {
        int percentPos;
        Intrinsics.checkNotNullParameter((Object)ipAddress, (String)"ipAddress");
        String fixedIp = ipAddress;
        if (fixedIp.charAt(0) == '[') {
            String string = fixedIp.substring(1, fixedIp.length() - 1);
            Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
            fixedIp = string;
        }
        if ((percentPos = StringsKt.indexOf$default((CharSequence)fixedIp, (char)'%', (int)0, (boolean)false, (int)6, null)) >= 0) {
            String string = fixedIp.substring(0, percentPos);
            Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
            fixedIp = string;
        }
        Inet6Address inet6Address = this.toAddress(fixedIp);
        byte[] byArray = (byte[])(inet6Address != null ? inet6Address.getAddress() : null);
        if (byArray == null) {
            byArray = new byte[32];
        }
        return byArray;
    }

    @NotNull
    public final BigInteger toInt(@NotNull byte[] ipBytes) {
        Intrinsics.checkNotNullParameter((Object)ipBytes, (String)"ipBytes");
        return new BigInteger(ipBytes);
    }

    @NotNull
    public final BigInteger toInt(@NotNull String ipAsString) {
        Intrinsics.checkNotNullParameter((Object)ipAsString, (String)"ipAsString");
        return this.isValid(ipAsString) ? this.toIntUnsafe(ipAsString) : new BigInteger(new byte[0]);
    }

    @NotNull
    public final BigInteger toIntUnsafe(@NotNull String ipAsString) {
        Intrinsics.checkNotNullParameter((Object)ipAsString, (String)"ipAsString");
        byte[] bytes = this.toBytes(ipAsString);
        return new BigInteger(bytes);
    }

    @NotNull
    public final String toString(@NotNull byte[] bytes) {
        Intrinsics.checkNotNullParameter((Object)bytes, (String)"bytes");
        return this.toString(bytes, 0);
    }

    @NotNull
    public final String toString(@NotNull int[] ints) {
        Intrinsics.checkNotNullParameter((Object)ints, (String)"ints");
        return this.toString(ints, 0);
    }

    public final void toString(@NotNull byte[] bytes, @NotNull StringBuilder buf) {
        Intrinsics.checkNotNullParameter((Object)bytes, (String)"bytes");
        Intrinsics.checkNotNullParameter((Object)buf, (String)"buf");
        this.toString(bytes, 0, buf);
    }

    public final void toString(@NotNull int[] ints, @NotNull StringBuilder buf) {
        Intrinsics.checkNotNullParameter((Object)ints, (String)"ints");
        Intrinsics.checkNotNullParameter((Object)buf, (String)"buf");
        this.toString(ints, 0, buf);
    }

    @NotNull
    public final String toString(@NotNull byte[] bytes, int offset) {
        Intrinsics.checkNotNullParameter((Object)bytes, (String)"bytes");
        StringBuilder buf = new StringBuilder(39);
        this.toAddressString(bytes, offset, false, buf);
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    @NotNull
    public final String toString(@NotNull int[] ints, int offset) {
        Intrinsics.checkNotNullParameter((Object)ints, (String)"ints");
        StringBuilder buf = new StringBuilder(39);
        this.toAddressString(ints, offset, false, buf);
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    public final void toString(@NotNull byte[] bytes, int offset, @NotNull StringBuilder buf) {
        Intrinsics.checkNotNullParameter((Object)bytes, (String)"bytes");
        Intrinsics.checkNotNullParameter((Object)buf, (String)"buf");
        this.toAddressString(bytes, offset, false, buf);
    }

    public final void toString(@NotNull int[] ints, int offset, @NotNull StringBuilder buf) {
        Intrinsics.checkNotNullParameter((Object)ints, (String)"ints");
        Intrinsics.checkNotNullParameter((Object)buf, (String)"buf");
        this.toAddressString(ints, offset, false, buf);
    }

    @NotNull
    public final String toString(@NotNull Inet6Address ip, boolean ipv4Mapped) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        StringBuilder buf = new StringBuilder(39);
        byte[] byArray = ip.getAddress();
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"ip.address");
        this.toAddressString(byArray, 0, ipv4Mapped, buf);
        String string = buf.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"buf.toString()");
        return string;
    }

    public static /* synthetic */ String toString$default(IPv6 iPv6, Inet6Address inet6Address, boolean bl, int n, Object object) {
        if ((n & 2) != 0) {
            bl = false;
        }
        return iPv6.toString(inet6Address, bl);
    }

    public final void toString(@NotNull Inet6Address ip, boolean ipv4Mapped, @NotNull StringBuilder buf) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        Intrinsics.checkNotNullParameter((Object)buf, (String)"buf");
        byte[] byArray = ip.getAddress();
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"ip.address");
        this.toAddressString(byArray, 0, ipv4Mapped, buf);
    }

    public static /* synthetic */ void toString$default(IPv6 iPv6, Inet6Address inet6Address, boolean bl, StringBuilder stringBuilder, int n, Object object) {
        if ((n & 2) != 0) {
            bl = false;
        }
        iPv6.toString(inet6Address, bl, stringBuilder);
    }

    private final void toAddressString(byte[] bytes, int offset, boolean ipv4Mapped, StringBuilder buf) {
        int shortestEnd;
        int[] words = new int[8];
        int i = 0;
        int end = offset + words.length;
        for (i = offset; i < end; ++i) {
            words[i] = (bytes[i << 1] & 0xFF) << 8 | bytes[(i << 1) + 1] & 0xFF;
        }
        int currentStart = -1;
        int currentLength = 0;
        int shortestStart = -1;
        int shortestLength = 0;
        for (i = 0; i < words.length; ++i) {
            if (words[i] == 0) {
                if (currentStart >= 0) continue;
                currentStart = i;
                continue;
            }
            if (currentStart < 0) continue;
            currentLength = i - currentStart;
            if (currentLength > shortestLength) {
                shortestStart = currentStart;
                shortestLength = currentLength;
            }
            currentStart = -1;
        }
        if (currentStart >= 0 && (currentLength = i - currentStart) > shortestLength) {
            shortestStart = currentStart;
            shortestLength = currentLength;
        }
        if (shortestLength == 1) {
            shortestLength = 0;
            shortestStart = -1;
        }
        if ((shortestEnd = shortestStart + shortestLength) < 0) {
            buf.append(Integer.toHexString(words[0]));
            for (i = 1; i < words.length; ++i) {
                buf.append(':');
                buf.append(Integer.toHexString(words[i]));
            }
        } else {
            boolean bl;
            boolean isIpv4Mapped = false;
            if (this.inRangeEndExclusive(0, shortestStart, shortestEnd)) {
                buf.append("::");
                bl = ipv4Mapped && shortestEnd == 5 && words[5] == 65535;
            } else {
                buf.append(Integer.toHexString(words[0]));
                bl = false;
            }
            isIpv4Mapped = bl;
            for (i = 1; i < words.length; ++i) {
                if (!this.inRangeEndExclusive(i, shortestStart, shortestEnd)) {
                    if (!this.inRangeEndExclusive(i - 1, shortestStart, shortestEnd)) {
                        if (!isIpv4Mapped || i == 6) {
                            buf.append(':');
                        } else {
                            buf.append('.');
                        }
                    }
                    if (isIpv4Mapped && i > 5) {
                        buf.append(words[i] >> 8);
                        buf.append('.');
                        buf.append(words[i] & 0xFF);
                        continue;
                    }
                    buf.append(Integer.toHexString(words[i]));
                    continue;
                }
                if (this.inRangeEndExclusive(i - 1, shortestStart, shortestEnd)) continue;
                buf.append("::");
            }
        }
    }

    private final void toAddressString(int[] ints, int offset, boolean ipv4Mapped, StringBuilder buf) {
        int shortestEnd;
        int[] words = new int[8];
        int i = 0;
        int end = offset + words.length;
        for (i = offset; i < end; ++i) {
            words[i] = ints[i << 1] << 8 | ints[(i << 1) + 1];
        }
        int currentStart = -1;
        int currentLength = 0;
        int shortestStart = -1;
        int shortestLength = 0;
        for (i = 0; i < words.length; ++i) {
            if (words[i] == 0) {
                if (currentStart >= 0) continue;
                currentStart = i;
                continue;
            }
            if (currentStart < 0) continue;
            currentLength = i - currentStart;
            if (currentLength > shortestLength) {
                shortestStart = currentStart;
                shortestLength = currentLength;
            }
            currentStart = -1;
        }
        if (currentStart >= 0 && (currentLength = i - currentStart) > shortestLength) {
            shortestStart = currentStart;
            shortestLength = currentLength;
        }
        if (shortestLength == 1) {
            shortestLength = 0;
            shortestStart = -1;
        }
        if ((shortestEnd = shortestStart + shortestLength) < 0) {
            buf.append(Integer.toHexString(words[0]));
            for (i = 1; i < words.length; ++i) {
                buf.append(':');
                buf.append(Integer.toHexString(words[i]));
            }
        } else {
            boolean bl;
            boolean isIpv4Mapped = false;
            if (this.inRangeEndExclusive(0, shortestStart, shortestEnd)) {
                buf.append("::");
                bl = ipv4Mapped && shortestEnd == 5 && words[5] == 65535;
            } else {
                buf.append(Integer.toHexString(words[0]));
                bl = false;
            }
            isIpv4Mapped = bl;
            for (i = 1; i < words.length; ++i) {
                if (!this.inRangeEndExclusive(i, shortestStart, shortestEnd)) {
                    if (!this.inRangeEndExclusive(i - 1, shortestStart, shortestEnd)) {
                        if (!isIpv4Mapped || i == 6) {
                            buf.append(':');
                        } else {
                            buf.append('.');
                        }
                    }
                    if (isIpv4Mapped && i > 5) {
                        buf.append(words[i] >> 8);
                        buf.append('.');
                        buf.append(words[i] & 0xFF);
                        continue;
                    }
                    buf.append(Integer.toHexString(words[i]));
                    continue;
                }
                if (this.inRangeEndExclusive(i - 1, shortestStart, shortestEnd)) continue;
                buf.append("::");
            }
        }
    }

    private final boolean inRangeEndExclusive(int value, int start, int end) {
        return value >= start && value < end;
    }

    public final boolean isLoopback(@NotNull String ipAsString) {
        Intrinsics.checkNotNullParameter((Object)ipAsString, (String)"ipAsString");
        int oneCount = 0;
        CharSequence $this$forEach$iv = ipAsString;
        boolean $i$f$forEach = false;
        for (int i = 0; i < $this$forEach$iv.length(); ++i) {
            char element$iv;
            char c = element$iv = $this$forEach$iv.charAt(i);
            boolean bl = false;
            char c2 = c;
            if (c2 == ':') continue;
            if (c2 == '1') {
                if (++oneCount <= 1) continue;
                return false;
            }
            return false;
        }
        return oneCount == 1;
    }

    @Nullable
    public final InetAddress truncate(@NotNull Inet6Address address, int maskLength) {
        InetAddress inetAddress;
        Intrinsics.checkNotNullParameter((Object)address, (String)"address");
        int maxMaskLength = length * 8;
        if (!(maskLength >= 0 && maskLength <= maxMaskLength)) {
            boolean $i$a$-require-IPv6$truncate$22 = false;
            String $i$a$-require-IPv6$truncate$22 = "invalid mask length";
            throw new IllegalArgumentException($i$a$-require-IPv6$truncate$22.toString());
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

    @NotNull
    public final BigInteger cidrPrefixToSubnetMask(int cidrPrefix) {
        BigInteger bigInteger = MINUS_ONE.shiftLeft(128 - cidrPrefix);
        Intrinsics.checkNotNullExpressionValue((Object)bigInteger, (String)"MINUS_ONE.shiftLeft(128 - cidrPrefix)");
        return bigInteger;
    }
}

