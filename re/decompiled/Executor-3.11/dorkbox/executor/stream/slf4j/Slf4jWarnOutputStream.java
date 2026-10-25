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

import dorkbox.executor.stream.slf4j.Slf4jOutputStream;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0010\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\bH\u0014\u00a8\u0006\t"}, d2={"Ldorkbox/executor/stream/slf4j/Slf4jWarnOutputStream;", "Ldorkbox/executor/stream/slf4j/Slf4jOutputStream;", "logger", "Lorg/slf4j/Logger;", "(Lorg/slf4j/Logger;)V", "processLine", "", "line", "", "Executor"})
public final class Slf4jWarnOutputStream
extends Slf4jOutputStream {
    public Slf4jWarnOutputStream(@NotNull Logger logger) {
        Intrinsics.checkNotNullParameter((Object)logger, (String)"logger");
        super(logger);
    }

    @Override
    protected void processLine(@NotNull String line) {
        Intrinsics.checkNotNullParameter((Object)line, (String)"line");
        this.getLogger().warn(line);
    }
}

