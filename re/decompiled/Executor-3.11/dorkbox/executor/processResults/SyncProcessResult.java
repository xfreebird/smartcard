/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.processResults;

import dorkbox.executor.processResults.ProcessOutput;
import dorkbox.executor.processResults.ProcessResult;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000.\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u0012\n\u0002\b\u0004\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0007\b\u0016\u0018\u00002\u00020\u0001B\u001d\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bR\u0014\u0010\u0004\u001a\u00020\u0005X\u0096\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\nR\u0014\u0010\u000b\u001a\u00020\fX\u0096D\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001b\u0010\u000f\u001a\u00020\u00108VX\u0096\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0013\u0010\u0014\u001a\u0004\b\u0011\u0010\u0012R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0016\u00a8\u0006\u0017"}, d2={"Ldorkbox/executor/processResults/SyncProcessResult;", "Ldorkbox/executor/processResults/ProcessResult;", "pid", "", "exitValue", "", "out", "", "(JI[B)V", "getExitValue", "()I", "hasOutput", "", "getHasOutput", "()Z", "output", "Ldorkbox/executor/processResults/ProcessOutput;", "getOutput", "()Ldorkbox/executor/processResults/ProcessOutput;", "output$delegate", "Lkotlin/Lazy;", "getPid", "()J", "Executor"})
public class SyncProcessResult
implements ProcessResult {
    private final long pid;
    private final int exitValue;
    @NotNull
    private final byte[] out;
    private final boolean hasOutput;
    @NotNull
    private final Lazy output$delegate;

    public SyncProcessResult(long pid, int exitValue, @NotNull byte[] out) {
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        this.pid = pid;
        this.exitValue = exitValue;
        this.out = out;
        this.hasOutput = true;
        this.output$delegate = LazyKt.lazy((Function0)((Function0)new Function0<ProcessOutput>(this){
            final /* synthetic */ SyncProcessResult this$0;
            {
                this.this$0 = $receiver;
                super(0);
            }

            @NotNull
            public final ProcessOutput invoke() {
                return new ProcessOutput(SyncProcessResult.access$getOut$p(this.this$0));
            }
        }));
    }

    public final long getPid() {
        return this.pid;
    }

    @Override
    public int getExitValue() {
        return this.exitValue;
    }

    @Override
    public boolean getHasOutput() {
        return this.hasOutput;
    }

    @NotNull
    public ProcessOutput getOutput() throws IllegalStateException {
        Lazy lazy = this.output$delegate;
        return (ProcessOutput)lazy.getValue();
    }

    public static final /* synthetic */ byte[] access$getOut$p(SyncProcessResult $this) {
        return $this.out;
    }
}

