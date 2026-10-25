/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.Structure
 *  kotlin.Metadata
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.JvmField
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil.jna.windows.structs;

import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import java.util.List;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.JvmField;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\n\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u000e\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u000f0\u000eH\u0014R\u0012\u0010\u0005\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0007\u001a\u00020\b8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\t\u001a\u00020\n8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u000b\u001a\u00020\b8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\f\u001a\u00020\n8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0010"}, d2={"Ldorkbox/netUtil/jna/windows/structs/SOCKADDR_IN6;", "Lcom/sun/jna/Structure;", "p", "Lcom/sun/jna/Pointer;", "(Lcom/sun/jna/Pointer;)V", "sin6_addr", "", "sin6_family", "", "sin6_flowinfo", "", "sin6_port", "sin6_scope_id", "getFieldOrder", "", "", "NetworkUtils"})
public final class SOCKADDR_IN6
extends Structure {
    @JvmField
    public short sin6_family;
    @JvmField
    public short sin6_port;
    @JvmField
    public int sin6_flowinfo;
    @JvmField
    @NotNull
    public byte[] sin6_addr;
    @JvmField
    public int sin6_scope_id;

    public SOCKADDR_IN6(@NotNull Pointer p) {
        Intrinsics.checkNotNullParameter((Object)p, (String)"p");
        super(p);
        this.sin6_addr = new byte[16];
        this.read();
    }

    @NotNull
    protected List<String> getFieldOrder() {
        Object[] objectArray = new String[]{"sin6_family", "sin6_port", "sin6_flowinfo", "sin6_addr", "sin6_scope_id"};
        return CollectionsKt.listOf((Object[])objectArray);
    }
}

