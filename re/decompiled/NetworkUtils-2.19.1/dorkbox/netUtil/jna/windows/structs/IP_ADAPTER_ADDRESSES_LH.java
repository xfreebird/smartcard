/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByReference
 *  com.sun.jna.WString
 *  com.sun.jna.platform.win32.Guid$GUID
 *  kotlin.Metadata
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.JvmField
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil.jna.windows.structs;

import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import com.sun.jna.WString;
import com.sun.jna.platform.win32.Guid;
import dorkbox.netUtil.jna.windows.structs.IP_ADAPTER_ANYCAST_ADDRESS_XP;
import dorkbox.netUtil.jna.windows.structs.IP_ADAPTER_DNS_SERVER_ADDRESS_XP;
import dorkbox.netUtil.jna.windows.structs.IP_ADAPTER_DNS_SUFFIX;
import dorkbox.netUtil.jna.windows.structs.IP_ADAPTER_MULTICAST_ADDRESS_XP;
import dorkbox.netUtil.jna.windows.structs.IP_ADAPTER_UNICAST_ADDRESS_LH;
import dorkbox.netUtil.jna.windows.structs.LUID;
import dorkbox.netUtil.jna.windows.structs.SOCKET_ADDRESS;
import java.util.List;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.JvmField;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0084\u0001\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0012\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\n\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\t\n\u0002\b\u0003\n\u0002\u0010\u0015\n\u0000\n\u0002\u0010 \n\u0002\b\u0002\b\u0016\u0018\u00002\u00020\u0001:\u0001<B\u000f\b\u0016\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004B\u0007\b\u0016\u00a2\u0006\u0002\u0010\u0005J\u000e\u0010:\u001a\b\u0012\u0004\u0012\u00020\u00070;H\u0014R\u0014\u0010\u0006\u001a\u0004\u0018\u00010\u00078\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\b\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\n\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u000b\u001a\u0004\u0018\u00010\f8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\r\u001a\u0004\u0018\u00010\u000e8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u000f\u001a\u00020\u00108\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0011\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0012\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0013\u001a\u0004\u0018\u00010\u000e8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0014\u001a\u0004\u0018\u00010\f8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0015\u001a\u0004\u0018\u00010\u00168\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0017\u001a\u0004\u0018\u00010\u00188\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0019\u001a\u0004\u0018\u00010\u001a8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u001b\u001a\u0004\u0018\u00010\u00038\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u001c\u001a\u0004\u0018\u00010\u001d8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u001e\u001a\u0004\u0018\u00010\u00038\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u001f\u001a\u0004\u0018\u00010 8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010!\u001a\u0004\u0018\u00010\u00038\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\"\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010#\u001a\u0004\u0018\u00010\f8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010$\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010%\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010&\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010'\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010(\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010)\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010*\u001a\u0004\u0018\u00010+8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010,\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010-\u001a\u0004\u0018\u00010.8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010/\u001a\u0004\u0018\u0001008\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u00101\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u00102\u001a\u00020\u00108\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u00103\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u00104\u001a\u0002058\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u00106\u001a\u0002058\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u00107\u001a\u00020\t8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u00108\u001a\u0002098\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006="}, d2={"Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_ADDRESSES_LH;", "Lcom/sun/jna/Structure;", "p", "Lcom/sun/jna/Pointer;", "(Lcom/sun/jna/Pointer;)V", "()V", "AdapterName", "", "CompartmentId", "", "ConnectionType", "Description", "Lcom/sun/jna/WString;", "Dhcpv4Server", "Ldorkbox/netUtil/jna/windows/structs/SOCKET_ADDRESS;", "Dhcpv6ClientDuid", "", "Dhcpv6ClientDuidLength", "Dhcpv6Iaid", "Dhcpv6Server", "DnsSuffix", "FirstAnycastAddress", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_ANYCAST_ADDRESS_XP$ByReference;", "FirstDnsServerAddress", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_DNS_SERVER_ADDRESS_XP$ByReference;", "FirstDnsSuffix", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_DNS_SUFFIX$ByReference;", "FirstGatewayAddress", "FirstMulticastAddress", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_MULTICAST_ADDRESS_XP$ByReference;", "FirstPrefix", "FirstUnicastAddress", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_UNICAST_ADDRESS_LH$ByReference;", "FirstWinsServerAddress", "Flags", "FriendlyName", "IfIndex", "IfType", "Ipv4Metric", "Ipv6IfIndex", "Ipv6Metric", "Length", "Luid", "Ldorkbox/netUtil/jna/windows/structs/LUID;", "Mtu", "NetworkGuid", "Lcom/sun/jna/platform/win32/Guid$GUID;", "Next", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_ADDRESSES_LH$ByReference;", "OperStatus", "PhysicalAddress", "PhysicalAddressLength", "ReceiveLinkSpeed", "", "TransmitLinkSpeed", "TunnelType", "ZoneIndices", "", "getFieldOrder", "", "ByReference", "NetworkUtils"})
public class IP_ADAPTER_ADDRESSES_LH
extends Structure {
    @JvmField
    public int Length;
    @JvmField
    public int IfIndex;
    @JvmField
    @Nullable
    public ByReference Next;
    @JvmField
    @Nullable
    public String AdapterName;
    @JvmField
    @Nullable
    public IP_ADAPTER_UNICAST_ADDRESS_LH.ByReference FirstUnicastAddress;
    @JvmField
    @Nullable
    public IP_ADAPTER_ANYCAST_ADDRESS_XP.ByReference FirstAnycastAddress;
    @JvmField
    @Nullable
    public IP_ADAPTER_MULTICAST_ADDRESS_XP.ByReference FirstMulticastAddress;
    @JvmField
    @Nullable
    public IP_ADAPTER_DNS_SERVER_ADDRESS_XP.ByReference FirstDnsServerAddress;
    @JvmField
    @Nullable
    public WString DnsSuffix;
    @JvmField
    @Nullable
    public WString Description;
    @JvmField
    @Nullable
    public WString FriendlyName;
    @JvmField
    @NotNull
    public byte[] PhysicalAddress;
    @JvmField
    public int PhysicalAddressLength;
    @JvmField
    public int Flags;
    @JvmField
    public int Mtu;
    @JvmField
    public int IfType;
    @JvmField
    public int OperStatus;
    @JvmField
    public int Ipv6IfIndex;
    @JvmField
    @NotNull
    public int[] ZoneIndices;
    @JvmField
    @Nullable
    public Pointer FirstPrefix;
    @JvmField
    public long TransmitLinkSpeed;
    @JvmField
    public long ReceiveLinkSpeed;
    @JvmField
    @Nullable
    public Pointer FirstWinsServerAddress;
    @JvmField
    @Nullable
    public Pointer FirstGatewayAddress;
    @JvmField
    public int Ipv4Metric;
    @JvmField
    public int Ipv6Metric;
    @JvmField
    @Nullable
    public LUID Luid;
    @JvmField
    @Nullable
    public SOCKET_ADDRESS Dhcpv4Server;
    @JvmField
    public int CompartmentId;
    @JvmField
    @Nullable
    public Guid.GUID NetworkGuid;
    @JvmField
    public int ConnectionType;
    @JvmField
    public int TunnelType;
    @JvmField
    @Nullable
    public SOCKET_ADDRESS Dhcpv6Server;
    @JvmField
    @NotNull
    public byte[] Dhcpv6ClientDuid;
    @JvmField
    public int Dhcpv6ClientDuidLength;
    @JvmField
    public int Dhcpv6Iaid;
    @JvmField
    @Nullable
    public IP_ADAPTER_DNS_SUFFIX.ByReference FirstDnsSuffix;

    public IP_ADAPTER_ADDRESSES_LH(@NotNull Pointer p) {
        Intrinsics.checkNotNullParameter((Object)p, (String)"p");
        super(p);
        this.PhysicalAddress = new byte[8];
        this.ZoneIndices = new int[16];
        this.Dhcpv6ClientDuid = new byte[130];
        this.read();
    }

    public IP_ADAPTER_ADDRESSES_LH() {
        this.PhysicalAddress = new byte[8];
        this.ZoneIndices = new int[16];
        this.Dhcpv6ClientDuid = new byte[130];
    }

    @NotNull
    protected List<String> getFieldOrder() {
        Object[] objectArray = new String[]{"Length", "IfIndex", "Next", "AdapterName", "FirstUnicastAddress", "FirstAnycastAddress", "FirstMulticastAddress", "FirstDnsServerAddress", "DnsSuffix", "Description", "FriendlyName", "PhysicalAddress", "PhysicalAddressLength", "Flags", "Mtu", "IfType", "OperStatus", "Ipv6IfIndex", "ZoneIndices", "FirstPrefix", "TransmitLinkSpeed", "ReceiveLinkSpeed", "FirstWinsServerAddress", "FirstGatewayAddress", "Ipv4Metric", "Ipv6Metric", "Luid", "Dhcpv4Server", "CompartmentId", "NetworkGuid", "ConnectionType", "TunnelType", "Dhcpv6Server", "Dhcpv6ClientDuid", "Dhcpv6ClientDuidLength", "Dhcpv6Iaid", "FirstDnsSuffix"};
        return CollectionsKt.listOf((Object[])objectArray);
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u00012\u00020\u0002B\u0005\u00a2\u0006\u0002\u0010\u0003\u00a8\u0006\u0004"}, d2={"Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_ADDRESSES_LH$ByReference;", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_ADDRESSES_LH;", "Lcom/sun/jna/Structure$ByReference;", "()V", "NetworkUtils"})
    public static final class ByReference
    extends IP_ADAPTER_ADDRESSES_LH
    implements Structure.ByReference {
    }
}

