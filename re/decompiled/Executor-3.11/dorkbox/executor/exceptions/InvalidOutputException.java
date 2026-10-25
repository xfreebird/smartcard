/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.exceptions;

import dorkbox.executor.exceptions.InvalidResultException;
import dorkbox.executor.processResults.ProcessResult;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0018\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\u0015\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006\u00a8\u0006\u0007"}, d2={"Ldorkbox/executor/exceptions/InvalidOutputException;", "Ldorkbox/executor/exceptions/InvalidResultException;", "message", "", "result", "Ldorkbox/executor/processResults/ProcessResult;", "(Ljava/lang/String;Ldorkbox/executor/processResults/ProcessResult;)V", "Executor"})
public final class InvalidOutputException
extends InvalidResultException {
    public InvalidOutputException(@NotNull String message, @NotNull ProcessResult result) {
        Intrinsics.checkNotNullParameter((Object)message, (String)"message");
        Intrinsics.checkNotNullParameter((Object)result, (String)"result");
        super(message, result);
    }
}

