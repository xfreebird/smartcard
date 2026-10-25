/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 *  com.sun.jna.Structure$ByReference
 *  kotlin.Metadata
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.JvmField
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil.jna.windows.structs;

import com.sun.jna.Structure;
import dorkbox.netUtil.jna.windows.structs.SOCKET_ADDRESS;
import java.util.List;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.JvmField;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00004\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0005\n\u0002\b\u0005\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0002\b\u0002\b\u0016\u0018\u00002\u00020\u0001:\u0001\u0015B\u0005\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0012\u001a\b\u0012\u0004\u0012\u00020\u00140\u0013H\u0014R\u0014\u0010\u0003\u001a\u0004\u0018\u00010\u00048\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0005\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0007\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\b\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\t\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\n\u001a\u0004\u0018\u00010\u000b8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\f\u001a\u00020\r8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u000e\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u000f\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0010\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0011\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0016"}, d2={"Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_UNICAST_ADDRESS_LH;", "Lcom/sun/jna/Structure;", "()V", "Address", "Ldorkbox/netUtil/jna/windows/structs/SOCKET_ADDRESS;", "DadState", "", "IfIndex", "LeaseLifetime", "Length", "Next", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_UNICAST_ADDRESS_LH$ByReference;", "OnLinkPrefixLength", "", "PreferredLifetime", "PrefixOrigin", "SuffixOrigin", "ValidLifetime", "getFieldOrder", "", "", "ByReference", "NetworkUtils"})
public class IP_ADAPTER_UNICAST_ADDRESS_LH
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
    public SOCKET_ADDRESS Address;
    @JvmField
    public int PrefixOrigin;
    @JvmField
    public int SuffixOrigin;
    @JvmField
    public int DadState;
    @JvmField
    public int ValidLifetime;
    @JvmField
    public int PreferredLifetime;
    @JvmField
    public int LeaseLifetime;
    @JvmField
    public byte OnLinkPrefixLength;

    @NotNull
    protected List<String> getFieldOrder() {
        Object[] objectArray = new String[]{"Length", "IfIndex", "Next", "Address", "PrefixOrigin", "SuffixOrigin", "DadState", "ValidLifetime", "PreferredLifetime", "LeaseLifetime", "OnLinkPrefixLength"};
        return CollectionsKt.listOf((Object[])objectArray);
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u00012\u00020\u0002B\u0005\u00a2\u0006\u0002\u0010\u0003\u00a8\u0006\u0004"}, d2={"Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_UNICAST_ADDRESS_LH$ByReference;", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_UNICAST_ADDRESS_LH;", "Lcom/sun/jna/Structure$ByReference;", "()V", "NetworkUtils"})
    public static final class ByReference
    extends IP_ADAPTER_UNICAST_ADDRESS_LH
    implements Structure.ByReference {
    }
}

