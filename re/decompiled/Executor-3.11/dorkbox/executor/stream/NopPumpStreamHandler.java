/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.coroutines.Continuation
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor.stream;

import dorkbox.executor.stream.IOStreamHandler;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000 \n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0005\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J \u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\bH\u0016J!\u0010\n\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u000b\u001a\u00020\bH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\f\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\r"}, d2={"Ldorkbox/executor/stream/NopPumpStreamHandler;", "Ldorkbox/executor/stream/IOStreamHandler;", "()V", "start", "", "process", "Ljava/lang/Process;", "separateErrorStream", "", "highPerformanceIO", "stop", "finishedCleanly", "(Ljava/lang/Process;ZLkotlin/coroutines/Continuation;)Ljava/lang/Object;", "Executor"})
public final class NopPumpStreamHandler
extends IOStreamHandler {
    public NopPumpStreamHandler() {
        super(null, null, null, false, 15, null);
    }

    @Override
    public void start(@NotNull Process process, boolean separateErrorStream, boolean highPerformanceIO) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
    }

    @Override
    @Nullable
    public Object stop(@NotNull Process process, boolean finishedCleanly, @NotNull Continuation<? super Unit> $completion) {
        return Unit.INSTANCE;
    }
}

