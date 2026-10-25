/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.jvm.functions.Function0
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil;

import dorkbox.netUtil.Hosts;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.jvm.functions.Function0;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0006\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u001b\u0010\u0003\u001a\u00020\u00048FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0007\u0010\b\u001a\u0004\b\u0005\u0010\u0006R\u000e\u0010\t\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\n"}, d2={"Ldorkbox/netUtil/Hosts;", "", "()V", "name", "", "getName", "()Ljava/lang/String;", "name$delegate", "Lkotlin/Lazy;", "version", "NetworkUtils"})
public final class Hosts {
    @NotNull
    public static final Hosts INSTANCE = new Hosts();
    @NotNull
    public static final String version = "2.19.1";
    @NotNull
    private static final Lazy name$delegate = LazyKt.lazy((Function0)name.2.INSTANCE);

    private Hosts() {
    }

    @NotNull
    public final String getName() {
        Lazy lazy = name$delegate;
        return (String)lazy.getValue();
    }
}

