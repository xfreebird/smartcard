/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.NoWhenBranchMatchedException
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil.dnsUtils;

import dorkbox.netUtil.dnsUtils.DefaultHostsFileResolver;
import dorkbox.netUtil.dnsUtils.HostsFileEntries;
import dorkbox.netUtil.dnsUtils.ResolvedAddressTypes;
import java.net.Inet4Address;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.util.Locale;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.NoWhenBranchMatchedException;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0018\u0010\t\u001a\u0004\u0018\u00010\n2\u0006\u0010\u000b\u001a\u00020\f2\u0006\u0010\r\u001a\u00020\u000eJ\u0010\u0010\u000f\u001a\u00020\f2\u0006\u0010\u000b\u001a\u00020\fH\u0002R\u001b\u0010\u0003\u001a\u00020\u00048BX\u0082\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0007\u0010\b\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u0010"}, d2={"Ldorkbox/netUtil/dnsUtils/DefaultHostsFileResolver;", "", "()V", "parseEntries", "Ldorkbox/netUtil/dnsUtils/HostsFileEntries;", "getParseEntries", "()Ldorkbox/netUtil/dnsUtils/HostsFileEntries;", "parseEntries$delegate", "Lkotlin/Lazy;", "address", "Ljava/net/InetAddress;", "inetHost", "", "resolvedAddressTypes", "Ldorkbox/netUtil/dnsUtils/ResolvedAddressTypes;", "normalize", "NetworkUtils"})
public final class DefaultHostsFileResolver {
    @NotNull
    public static final DefaultHostsFileResolver INSTANCE = new DefaultHostsFileResolver();
    @NotNull
    private static final Lazy parseEntries$delegate = LazyKt.lazy((Function0)parseEntries.2.INSTANCE);

    private DefaultHostsFileResolver() {
    }

    private final HostsFileEntries getParseEntries() {
        Lazy lazy = parseEntries$delegate;
        return (HostsFileEntries)lazy.getValue();
    }

    @Nullable
    public final InetAddress address(@NotNull String inetHost, @NotNull ResolvedAddressTypes resolvedAddressTypes) {
        InetAddress inetAddress;
        Intrinsics.checkNotNullParameter((Object)inetHost, (String)"inetHost");
        Intrinsics.checkNotNullParameter((Object)((Object)resolvedAddressTypes), (String)"resolvedAddressTypes");
        String normalized = this.normalize(inetHost);
        switch (WhenMappings.$EnumSwitchMapping$0[resolvedAddressTypes.ordinal()]) {
            case 1: {
                inetAddress = this.getParseEntries().getIpv4Entries().get(normalized);
                break;
            }
            case 2: {
                inetAddress = this.getParseEntries().getIpv6Entries().get(normalized);
                break;
            }
            case 3: {
                Inet4Address inet4Address = this.getParseEntries().getIpv4Entries().get(normalized);
                if (inet4Address != null) {
                    inetAddress = inet4Address;
                    break;
                }
                inetAddress = this.getParseEntries().getIpv6Entries().get(normalized);
                break;
            }
            case 4: {
                Inet6Address inet6Address = this.getParseEntries().getIpv6Entries().get(normalized);
                if (inet6Address != null) {
                    inetAddress = inet6Address;
                    break;
                }
                inetAddress = this.getParseEntries().getIpv4Entries().get(normalized);
                break;
            }
            default: {
                throw new NoWhenBranchMatchedException();
            }
        }
        return inetAddress;
    }

    private final String normalize(String inetHost) {
        String string = inetHost;
        Locale locale = Locale.ENGLISH;
        Intrinsics.checkNotNullExpressionValue((Object)locale, (String)"ENGLISH");
        String string2 = string.toLowerCase(locale);
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).toLowerCase(locale)");
        return string2;
    }

    @Metadata(mv={1, 7, 1}, k=3, xi=48)
    public final class WhenMappings {
        public static final /* synthetic */ int[] $EnumSwitchMapping$0;

        static {
            int[] nArray = new int[ResolvedAddressTypes.values().length];
            try {
                nArray[ResolvedAddressTypes.IPV4_ONLY.ordinal()] = 1;
            }
            catch (NoSuchFieldError noSuchFieldError) {
                // empty catch block
            }
            try {
                nArray[ResolvedAddressTypes.IPV6_ONLY.ordinal()] = 2;
            }
            catch (NoSuchFieldError noSuchFieldError) {
                // empty catch block
            }
            try {
                nArray[ResolvedAddressTypes.IPV4_PREFERRED.ordinal()] = 3;
            }
            catch (NoSuchFieldError noSuchFieldError) {
                // empty catch block
            }
            try {
                nArray[ResolvedAddressTypes.IPV6_PREFERRED.ordinal()] = 4;
            }
            catch (NoSuchFieldError noSuchFieldError) {
                // empty catch block
            }
            $EnumSwitchMapping$0 = nArray;
        }
    }
}

