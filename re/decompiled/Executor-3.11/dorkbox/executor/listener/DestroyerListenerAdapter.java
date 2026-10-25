/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.listener;

import dorkbox.executor.Executor;
import dorkbox.executor.listener.ProcessDestroyer;
import dorkbox.executor.listener.ProcessListener;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000&\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0018\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\nH\u0016J\u0010\u0010\u000b\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\bH\u0016R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\f"}, d2={"Ldorkbox/executor/listener/DestroyerListenerAdapter;", "Ldorkbox/executor/listener/ProcessListener;", "destroyer", "Ldorkbox/executor/listener/ProcessDestroyer;", "(Ldorkbox/executor/listener/ProcessDestroyer;)V", "afterStart", "", "process", "Ljava/lang/Process;", "executor", "Ldorkbox/executor/Executor;", "afterStop", "Executor"})
public final class DestroyerListenerAdapter
extends ProcessListener {
    @NotNull
    private final ProcessDestroyer destroyer;

    public DestroyerListenerAdapter(@NotNull ProcessDestroyer destroyer) {
        Intrinsics.checkNotNullParameter((Object)destroyer, (String)"destroyer");
        this.destroyer = destroyer;
    }

    @Override
    public void afterStart(@NotNull Process process, @NotNull Executor executor) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        Intrinsics.checkNotNullParameter((Object)executor, (String)"executor");
        this.destroyer.add(process);
    }

    @Override
    public void afterStop(@NotNull Process process) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        this.destroyer.remove(process);
    }
}

