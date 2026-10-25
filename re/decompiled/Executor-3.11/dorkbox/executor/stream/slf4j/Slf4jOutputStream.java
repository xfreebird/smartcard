/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.slf4j.Logger
 */
package dorkbox.executor.stream.slf4j;

import dorkbox.executor.stream.LogOutputStream;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\b&\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u0007"}, d2={"Ldorkbox/executor/stream/slf4j/Slf4jOutputStream;", "Ldorkbox/executor/stream/LogOutputStream;", "logger", "Lorg/slf4j/Logger;", "(Lorg/slf4j/Logger;)V", "getLogger", "()Lorg/slf4j/Logger;", "Executor"})
public abstract class Slf4jOutputStream
extends LogOutputStream {
    @NotNull
    private final Logger logger;

    public Slf4jOutputStream(@NotNull Logger logger) {
        Intrinsics.checkNotNullParameter((Object)logger, (String)"logger");
        this.logger = logger;
    }

    @NotNull
    public final Logger getLogger() {
        return this.logger;
    }
}

