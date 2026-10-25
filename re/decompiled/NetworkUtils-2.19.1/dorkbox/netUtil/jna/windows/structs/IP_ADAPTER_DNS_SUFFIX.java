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
import java.util.List;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.JvmField;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000$\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0019\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0002\b\u0002\b\u0016\u0018\u00002\u00020\u0001:\u0001\nB\u0005\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\bH\u0014R\u0014\u0010\u0003\u001a\u0004\u0018\u00010\u00048\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0005\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u000b"}, d2={"Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_DNS_SUFFIX;", "Lcom/sun/jna/Structure;", "()V", "Next", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_DNS_SUFFIX$ByReference;", "_String", "", "getFieldOrder", "", "", "ByReference", "NetworkUtils"})
public class IP_ADAPTER_DNS_SUFFIX
extends Structure {
    @JvmField
    @Nullable
    public ByReference Next;
    @JvmField
    @NotNull
    public char[] _String = new char[256];

    @NotNull
    protected List<String> getFieldOrder() {
        Object[] objectArray = new String[]{"Next", "_String"};
        return CollectionsKt.listOf((Object[])objectArray);
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u00012\u00020\u0002B\u0005\u00a2\u0006\u0002\u0010\u0003\u00a8\u0006\u0004"}, d2={"Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_DNS_SUFFIX$ByReference;", "Ldorkbox/netUtil/jna/windows/structs/IP_ADAPTER_DNS_SUFFIX;", "Lcom/sun/jna/Structure$ByReference;", "()V", "NetworkUtils"})
    public static final class ByReference
    extends IP_ADAPTER_DNS_SUFFIX
    implements Structure.ByReference {
    }
}

