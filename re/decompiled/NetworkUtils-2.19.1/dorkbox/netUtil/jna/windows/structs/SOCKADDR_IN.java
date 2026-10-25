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

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000*\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\n\n\u0002\b\u0003\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u000e\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\r0\fH\u0014R\u0012\u0010\u0005\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0007\u001a\u00020\b8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\t\u001a\u00020\b8\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\n\u001a\u00020\u00068\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u000e"}, d2={"Ldorkbox/netUtil/jna/windows/structs/SOCKADDR_IN;", "Lcom/sun/jna/Structure;", "p", "Lcom/sun/jna/Pointer;", "(Lcom/sun/jna/Pointer;)V", "sin_addr", "", "sin_family", "", "sin_port", "sin_zero", "getFieldOrder", "", "", "NetworkUtils"})
public final class SOCKADDR_IN
extends Structure {
    @JvmField
    public short sin_family;
    @JvmField
    public short sin_port;
    @JvmField
    @NotNull
    public byte[] sin_addr;
    @JvmField
    @NotNull
    public byte[] sin_zero;

    public SOCKADDR_IN(@NotNull Pointer p) {
        Intrinsics.checkNotNullParameter((Object)p, (String)"p");
        super(p);
        this.sin_addr = new byte[4];
        this.sin_zero = new byte[8];
        this.read();
    }

    @NotNull
    protected List<String> getFieldOrder() {
        Object[] objectArray = new String[]{"sin_family", "sin_port", "sin_addr", "sin_zero"};
        return CollectionsKt.listOf((Object[])objectArray);
    }
}

