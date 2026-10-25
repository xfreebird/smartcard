/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 */
package dorkbox.netUtil.dnsUtils;

import kotlin.Metadata;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0006\b\u0086\u0001\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005j\u0002\b\u0006\u00a8\u0006\u0007"}, d2={"Ldorkbox/netUtil/dnsUtils/ResolvedAddressTypes;", "", "(Ljava/lang/String;I)V", "IPV4_ONLY", "IPV6_ONLY", "IPV4_PREFERRED", "IPV6_PREFERRED", "NetworkUtils"})
public final class ResolvedAddressTypes
extends Enum<ResolvedAddressTypes> {
    public static final /* enum */ ResolvedAddressTypes IPV4_ONLY = new ResolvedAddressTypes();
    public static final /* enum */ ResolvedAddressTypes IPV6_ONLY = new ResolvedAddressTypes();
    public static final /* enum */ ResolvedAddressTypes IPV4_PREFERRED = new ResolvedAddressTypes();
    public static final /* enum */ ResolvedAddressTypes IPV6_PREFERRED = new ResolvedAddressTypes();
    private static final /* synthetic */ ResolvedAddressTypes[] $VALUES;

    public static ResolvedAddressTypes[] values() {
        return (ResolvedAddressTypes[])$VALUES.clone();
    }

    public static ResolvedAddressTypes valueOf(String value) {
        return Enum.valueOf(ResolvedAddressTypes.class, value);
    }

    static {
        $VALUES = resolvedAddressTypesArray = new ResolvedAddressTypes[]{ResolvedAddressTypes.IPV4_ONLY, ResolvedAddressTypes.IPV6_ONLY, ResolvedAddressTypes.IPV4_PREFERRED, ResolvedAddressTypes.IPV6_PREFERRED};
    }
}

