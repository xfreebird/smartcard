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
import dorkbox.executor.processResults.ProcessResult;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b&\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0018\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\bH\u0016J\u0018\u0010\t\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\n\u001a\u00020\u000bH\u0016J\u0010\u0010\f\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0006H\u0016J\u0010\u0010\r\u001a\u00020\u00042\u0006\u0010\n\u001a\u00020\u000bH\u0016\u00a8\u0006\u000e"}, d2={"Ldorkbox/executor/listener/ProcessListener;", "", "()V", "afterFinish", "", "process", "Ljava/lang/Process;", "result", "Ldorkbox/executor/processResults/ProcessResult;", "afterStart", "executor", "Ldorkbox/executor/Executor;", "afterStop", "beforeStart", "Executor"})
public abstract class ProcessListener {
    public void beforeStart(@NotNull Executor executor) {
        Intrinsics.checkNotNullParameter((Object)executor, (String)"executor");
    }

    public void afterStart(@NotNull Process process, @NotNull Executor executor) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        Intrinsics.checkNotNullParameter((Object)executor, (String)"executor");
    }

    public void afterFinish(@NotNull Process process, @NotNull ProcessResult result) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        Intrinsics.checkNotNullParameter((Object)result, (String)"result");
    }

    public void afterStop(@NotNull Process process) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
    }
}

