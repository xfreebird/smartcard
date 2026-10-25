/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.NoWhenBranchMatchedException
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.executor.stream.slf4j;

import dorkbox.executor.stream.CallerLoggerUtil;
import dorkbox.executor.stream.slf4j.Level;
import dorkbox.executor.stream.slf4j.Slf4jDebugOutputStream;
import dorkbox.executor.stream.slf4j.Slf4jErrorOutputStream;
import dorkbox.executor.stream.slf4j.Slf4jInfoOutputStream;
import dorkbox.executor.stream.slf4j.Slf4jOutputStream;
import dorkbox.executor.stream.slf4j.Slf4jTraceOutputStream;
import dorkbox.executor.stream.slf4j.Slf4jWarnOutputStream;
import kotlin.Metadata;
import kotlin.NoWhenBranchMatchedException;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000 \n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0006J\u0016\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0007\u001a\u00020\b2\u0006\u0010\u0005\u001a\u00020\u0006J\u0006\u0010\t\u001a\u00020\u0004J\u000e\u0010\t\u001a\u00020\u00042\u0006\u0010\u0007\u001a\u00020\bJ\u0006\u0010\n\u001a\u00020\u0004J\u000e\u0010\n\u001a\u00020\u00042\u0006\u0010\u0007\u001a\u00020\bJ\u0006\u0010\u000b\u001a\u00020\u0004J\u000e\u0010\u000b\u001a\u00020\u00042\u0006\u0010\u0007\u001a\u00020\bJ\u0006\u0010\f\u001a\u00020\u0004J\u000e\u0010\f\u001a\u00020\u00042\u0006\u0010\u0007\u001a\u00020\bJ\u0006\u0010\r\u001a\u00020\u0004J\u000e\u0010\r\u001a\u00020\u00042\u0006\u0010\u0007\u001a\u00020\b\u00a8\u0006\u000e"}, d2={"Ldorkbox/executor/stream/slf4j/Slf4jStream;", "", "()V", "as", "Ldorkbox/executor/stream/slf4j/Slf4jOutputStream;", "level", "Ldorkbox/executor/stream/slf4j/Level;", "log", "Lorg/slf4j/Logger;", "asDebug", "asError", "asInfo", "asTrace", "asWarn", "Executor"})
public final class Slf4jStream {
    @NotNull
    public static final Slf4jStream INSTANCE = new Slf4jStream();

    private Slf4jStream() {
    }

    @NotNull
    public final Slf4jOutputStream as(@NotNull Level level) {
        Slf4jOutputStream slf4jOutputStream;
        Intrinsics.checkNotNullParameter((Object)((Object)level), (String)"level");
        switch (WhenMappings.$EnumSwitchMapping$0[level.ordinal()]) {
            case 1: {
                slf4jOutputStream = this.asTrace();
                break;
            }
            case 2: {
                slf4jOutputStream = this.asDebug();
                break;
            }
            case 3: {
                slf4jOutputStream = this.asInfo();
                break;
            }
            case 4: {
                slf4jOutputStream = this.asWarn();
                break;
            }
            case 5: {
                slf4jOutputStream = this.asError();
                break;
            }
            default: {
                throw new NoWhenBranchMatchedException();
            }
        }
        return slf4jOutputStream;
    }

    @NotNull
    public final Slf4jOutputStream as(@NotNull Logger log, @NotNull Level level) {
        Slf4jOutputStream slf4jOutputStream;
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        Intrinsics.checkNotNullParameter((Object)((Object)level), (String)"level");
        switch (WhenMappings.$EnumSwitchMapping$0[level.ordinal()]) {
            case 1: {
                slf4jOutputStream = this.asTrace(log);
                break;
            }
            case 2: {
                slf4jOutputStream = this.asDebug(log);
                break;
            }
            case 3: {
                slf4jOutputStream = this.asInfo(log);
                break;
            }
            case 4: {
                slf4jOutputStream = this.asWarn(log);
                break;
            }
            case 5: {
                slf4jOutputStream = this.asError(log);
                break;
            }
            default: {
                throw new NoWhenBranchMatchedException();
            }
        }
        return slf4jOutputStream;
    }

    @NotNull
    public final Slf4jOutputStream asTrace() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 2));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(CallerLoggerUt\u2026null,\n                2))");
        return new Slf4jTraceOutputStream(logger);
    }

    @NotNull
    public final Slf4jOutputStream asDebug() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 2));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(CallerLoggerUt\u2026null,\n                2))");
        return new Slf4jDebugOutputStream(logger);
    }

    @NotNull
    public final Slf4jOutputStream asInfo() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 2));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(CallerLoggerUt\u2026null,\n                2))");
        return new Slf4jInfoOutputStream(logger);
    }

    @NotNull
    public final Slf4jOutputStream asWarn() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 2));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(CallerLoggerUt\u2026null,\n                2))");
        return new Slf4jWarnOutputStream(logger);
    }

    @NotNull
    public final Slf4jOutputStream asError() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 2));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(CallerLoggerUt\u2026null,\n                2))");
        return new Slf4jErrorOutputStream(logger);
    }

    @NotNull
    public final Slf4jOutputStream asTrace(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return new Slf4jTraceOutputStream(log);
    }

    @NotNull
    public final Slf4jOutputStream asDebug(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return new Slf4jDebugOutputStream(log);
    }

    @NotNull
    public final Slf4jOutputStream asInfo(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return new Slf4jInfoOutputStream(log);
    }

    @NotNull
    public final Slf4jOutputStream asWarn(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return new Slf4jWarnOutputStream(log);
    }

    @NotNull
    public final Slf4jOutputStream asError(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return new Slf4jErrorOutputStream(log);
    }

    @Metadata(mv={1, 6, 0}, k=3, xi=48)
    public final class WhenMappings {
        public static final /* synthetic */ int[] $EnumSwitchMapping$0;

        static {
            int[] nArray = new int[Level.values().length];
            nArray[Level.TRACE.ordinal()] = 1;
            nArray[Level.DEBUG.ordinal()] = 2;
            nArray[Level.INFO.ordinal()] = 3;
            nArray[Level.WARN.ordinal()] = 4;
            nArray[Level.ERROR.ordinal()] = 5;
            $EnumSwitchMapping$0 = nArray;
        }
    }
}

