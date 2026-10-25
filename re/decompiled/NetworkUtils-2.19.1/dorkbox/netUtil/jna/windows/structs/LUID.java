/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 *  kotlin.Metadata
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.JvmField
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil.jna.windows.structs;

import com.sun.jna.Structure;
import java.util.List;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.JvmField;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\b0\u0007H\u0014R\u0012\u0010\u0003\u001a\u00020\u00048\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0005\u001a\u00020\u00048\u0006@\u0006X\u0087\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\t"}, d2={"Ldorkbox/netUtil/jna/windows/structs/LUID;", "Lcom/sun/jna/Structure;", "()V", "HighPart", "", "LowPart", "getFieldOrder", "", "", "NetworkUtils"})
public final class LUID
extends Structure {
    @JvmField
    public int LowPart;
    @JvmField
    public int HighPart;

    @NotNull
    protected List<String> getFieldOrder() {
        Object[] objectArray = new String[]{"LowPart", "HighPart"};
        return CollectionsKt.listOf((Object[])objectArray);
    }
}

