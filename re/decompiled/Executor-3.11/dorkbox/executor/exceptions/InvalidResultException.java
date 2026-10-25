/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.exceptions;

import dorkbox.executor.processResults.ProcessResult;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000$\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0005\b\u0016\u0018\u00002\u00060\u0001j\u0002`\u0002B\u0015\u0012\u0006\u0010\u0003\u001a\u00020\u0004\u0012\u0006\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\u0002\u0010\u0007R\u0011\u0010\b\u001a\u00020\t8F\u00a2\u0006\u0006\u001a\u0004\b\n\u0010\u000bR\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\r\u00a8\u0006\u000e"}, d2={"Ldorkbox/executor/exceptions/InvalidResultException;", "Ljava/lang/RuntimeException;", "Lkotlin/RuntimeException;", "message", "", "result", "Ldorkbox/executor/processResults/ProcessResult;", "(Ljava/lang/String;Ldorkbox/executor/processResults/ProcessResult;)V", "exitValue", "", "getExitValue", "()I", "getResult", "()Ldorkbox/executor/processResults/ProcessResult;", "Executor"})
public class InvalidResultException
extends RuntimeException {
    @NotNull
    private final ProcessResult result;

    public InvalidResultException(@NotNull String message, @NotNull ProcessResult result) {
        Intrinsics.checkNotNullParameter((Object)message, (String)"message");
        Intrinsics.checkNotNullParameter((Object)result, (String)"result");
        super(message);
        this.result = result;
    }

    @NotNull
    public final ProcessResult getResult() {
        return this.result;
    }

    public final int getExitValue() {
        return this.result.getExitValue();
    }
}

