/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Charsets
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.processResults;

import dorkbox.executor.processResults.ProcessOutput;
import dorkbox.executor.processResults.SyncProcessResult;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Charsets;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000(\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0015\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006R\u0014\u0010\u0007\u001a\u00020\bX\u0096D\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\nR\u0014\u0010\u000b\u001a\u00020\f8VX\u0096\u0004\u00a2\u0006\u0006\u001a\u0004\b\r\u0010\u000e\u00a8\u0006\u000f"}, d2={"Ldorkbox/executor/processResults/NopProcessResult;", "Ldorkbox/executor/processResults/SyncProcessResult;", "pid", "", "exitValue", "", "(JI)V", "hasOutput", "", "getHasOutput", "()Z", "output", "Ldorkbox/executor/processResults/ProcessOutput;", "getOutput", "()Ldorkbox/executor/processResults/ProcessOutput;", "Executor"})
public final class NopProcessResult
extends SyncProcessResult {
    private final boolean hasOutput;

    public NopProcessResult(long pid, int exitValue) {
        String string2 = "";
        byte[] byArray = string2.getBytes(Charsets.UTF_8);
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"this as java.lang.String).getBytes(charset)");
        super(pid, exitValue, byArray);
    }

    @Override
    public boolean getHasOutput() {
        return this.hasOutput;
    }

    @Override
    @NotNull
    public ProcessOutput getOutput() throws IllegalStateException {
        throw new IllegalStateException("Process output was not read. To enable output reading please call ProcessExecutor.readOutput() before starting the process.");
    }
}

