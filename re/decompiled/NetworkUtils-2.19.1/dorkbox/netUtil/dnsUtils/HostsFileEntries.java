/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.collections.MapsKt
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil.dnsUtils;

import java.net.Inet4Address;
import java.net.Inet6Address;
import java.util.Map;
import kotlin.Metadata;
import kotlin.collections.MapsKt;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010$\n\u0002\u0010\u000e\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001B1\u0012\u0014\b\u0002\u0010\u0002\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00050\u0003\u0012\u0014\b\u0002\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00070\u0003\u00a2\u0006\u0002\u0010\bJ\u0015\u0010\f\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00050\u0003H\u00c6\u0003J\u0015\u0010\r\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00070\u0003H\u00c6\u0003J5\u0010\u000e\u001a\u00020\u00002\u0014\b\u0002\u0010\u0002\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00050\u00032\u0014\b\u0002\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00070\u0003H\u00c6\u0001J\u0013\u0010\u000f\u001a\u00020\u00102\b\u0010\u0011\u001a\u0004\u0018\u00010\u0001H\u0096\u0002J\b\u0010\u0012\u001a\u00020\u0013H\u0016J\t\u0010\u0014\u001a\u00020\u0004H\u00d6\u0001R\u001d\u0010\u0002\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00050\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\nR\u001d\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00070\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000b\u0010\n\u00a8\u0006\u0015"}, d2={"Ldorkbox/netUtil/dnsUtils/HostsFileEntries;", "", "ipv4Entries", "", "", "Ljava/net/Inet4Address;", "ipv6Entries", "Ljava/net/Inet6Address;", "(Ljava/util/Map;Ljava/util/Map;)V", "getIpv4Entries", "()Ljava/util/Map;", "getIpv6Entries", "component1", "component2", "copy", "equals", "", "other", "hashCode", "", "toString", "NetworkUtils"})
public final class HostsFileEntries {
    @NotNull
    private final Map<String, Inet4Address> ipv4Entries;
    @NotNull
    private final Map<String, Inet6Address> ipv6Entries;

    public HostsFileEntries(@NotNull Map<String, Inet4Address> ipv4Entries, @NotNull Map<String, Inet6Address> ipv6Entries) {
        Intrinsics.checkNotNullParameter(ipv4Entries, (String)"ipv4Entries");
        Intrinsics.checkNotNullParameter(ipv6Entries, (String)"ipv6Entries");
        this.ipv4Entries = ipv4Entries;
        this.ipv6Entries = ipv6Entries;
    }

    public /* synthetic */ HostsFileEntries(Map map, Map map2, int n, DefaultConstructorMarker defaultConstructorMarker) {
        if ((n & 1) != 0) {
            map = MapsKt.emptyMap();
        }
        if ((n & 2) != 0) {
            map2 = MapsKt.emptyMap();
        }
        this(map, map2);
    }

    @NotNull
    public final Map<String, Inet4Address> getIpv4Entries() {
        return this.ipv4Entries;
    }

    @NotNull
    public final Map<String, Inet6Address> getIpv6Entries() {
        return this.ipv6Entries;
    }

    public boolean equals(@Nullable Object other) {
        if (this == other) {
            return true;
        }
        Object object = other;
        if (!Intrinsics.areEqual(this.getClass(), object != null ? object.getClass() : null)) {
            return false;
        }
        Intrinsics.checkNotNull((Object)other, (String)"null cannot be cast to non-null type dorkbox.netUtil.dnsUtils.HostsFileEntries");
        HostsFileEntries cfr_ignored_0 = (HostsFileEntries)other;
        if (!Intrinsics.areEqual(this.ipv4Entries, ((HostsFileEntries)other).ipv4Entries)) {
            return false;
        }
        return Intrinsics.areEqual(this.ipv6Entries, ((HostsFileEntries)other).ipv6Entries);
    }

    public int hashCode() {
        int result = ((Object)this.ipv4Entries).hashCode();
        result = 31 * result + ((Object)this.ipv6Entries).hashCode();
        return result;
    }

    @NotNull
    public final Map<String, Inet4Address> component1() {
        return this.ipv4Entries;
    }

    @NotNull
    public final Map<String, Inet6Address> component2() {
        return this.ipv6Entries;
    }

    @NotNull
    public final HostsFileEntries copy(@NotNull Map<String, Inet4Address> ipv4Entries, @NotNull Map<String, Inet6Address> ipv6Entries) {
        Intrinsics.checkNotNullParameter(ipv4Entries, (String)"ipv4Entries");
        Intrinsics.checkNotNullParameter(ipv6Entries, (String)"ipv6Entries");
        return new HostsFileEntries(ipv4Entries, ipv6Entries);
    }

    public static /* synthetic */ HostsFileEntries copy$default(HostsFileEntries hostsFileEntries, Map map, Map map2, int n, Object object) {
        if ((n & 1) != 0) {
            map = hostsFileEntries.ipv4Entries;
        }
        if ((n & 2) != 0) {
            map2 = hostsFileEntries.ipv6Entries;
        }
        return hostsFileEntries.copy(map, map2);
    }

    @NotNull
    public String toString() {
        return "HostsFileEntries(ipv4Entries=" + this.ipv4Entries + ", ipv6Entries=" + this.ipv6Entries + ')';
    }

    public HostsFileEntries() {
        this(null, null, 3, null);
    }
}

